class HashStruct
  module HashieExtensions
    module ReadonlyProperties
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method :set_value_without_readonly_properties, :[]=
          alias_method :[]=, :set_value_with_readonly_properties
        end
      end

      module ClassMethods
        # Override Hashie to support readonly properties
        def property(name, options = {}, &block)
          updated_options =
            if options[:readonly]
              options.merge(default: block || -> {})
            else
              options
            end

          super(name, updated_options, &block).tap do |resolved_name|
            if options[:readonly]
              readonly_properties << resolved_name
            else
              readonly_properties.delete(resolved_name)
            end
          end
        end

        # Override Hashie to account for private options being passed to
        # HashStruct.new in #==
        def fetch_coercion(type, hash_struct_instance)
          coercion =
            if type.is_a? Proc
              type
            else
              coercion_cache[type]
            end

          lambda do |value|
            if coercion.arity == 2
              coercion.call(value, hash_struct_instance)
            else
              coercion.call(value)
            end
          end
        end

        # Override Hashie to pass along private options to HashStruct.new
        def build_hash_coercion(type, key_type, value_type)
          lambda do |value, hash_struct_instance|
            key_coerce = fetch_coercion(key_type, hash_struct_instance)
            value_coerce = fetch_coercion(value_type, hash_struct_instance)
            type[value.map { |k, v| [key_coerce.call(k), value_coerce.call(v)] }]
          end
        end

        # Override Hashie to pass along private options to HashStruct.new
        def build_container_coercion(type, value_type)
          lambda do |value, hash_struct_instance|
            value_coerce = fetch_coercion(value_type, hash_struct_instance)
            type.new(value.map { |v| value_coerce.call(v) })
          end
        end

        # Override AttributeMethods to support readonly properties
        def _writable_properties
          super - readonly_properties
        end

        # Override Aliases to support read-only properties
        def should_define_setter_for?(name, setter)
          super && !_readonly_property?(name)
        end

        def _readonly_property?(name)
          readonly_properties.include?(_resolve_property(name))
        end

        private

        # Override CustomCoercion to support read-only properties
        def build_coercion_for_hash_struct(type)
          -> (value, hash_struct) do
            hash_struct._wrap(
              value,
              with: type,
              inherit_allow_writing_readonly_properties: true
            )
          end
        end

        def readonly_properties
          @readonly_properties ||= Set.new
        end
      end

      # Override Hashie to support readonly properties (they come in via defaults
      # and are allowed to be initialized to nil, overriding the `required`
      # setting)
      def initialize(*args)
        if args.size == 2
          attributes, options = args
        else
          attributes, options = args[0], {}
        end

        @allow_writing_readonly_properties = true
        @allow_leaving_required_readonly_properties_blank = true

        self.class.defaults.each_pair do |prop, value|
          self[prop] =
            begin
              val = value.dup
              if val.is_a?(Proc)
                val.arity == 1 ? val.call(self) : val.call
              else
                val
              end
            rescue TypeError
              value
            end
        end

        @allow_writing_readonly_properties = options.fetch(
          :_allow_writing_readonly_properties,
          false
        )

        initialize_attributes(attributes)
        assert_required_attributes_set!

        @allow_leaving_required_readonly_properties_blank = false
      end

      # Override Hashie to account for readonly attributes
      def set_value_with_readonly_properties(name, value, override: false)
        if (
          self.class._readonly_property?(name) &&
          !allow_writing_readonly_properties? &&
          !override
        )
          raise_error!(
            "Couldn't write readonly attribute " +
            "#{self.class._describe_property(name)}."
          )
        else
          set_value_without_readonly_properties(name, value)
        end
      end

      # Override Equality to bypass readonly restriction when wrapping incoming
      # non-HashStruct in a HashStruct in #==
      def _wrap(
        value,
        with: self.class,
        inherit_allow_writing_readonly_properties: false
      )
        allow_writing_readonly_properties =
          if inherit_allow_writing_readonly_properties
            allow_writing_readonly_properties?
          else
            true
          end

        with.new(
          value,
          _allow_writing_readonly_properties: allow_writing_readonly_properties
        )
      end

      private

      # Override Hashie to allow a readonly attribute to have a default of nil
      def assert_property_required!(property, value)
        if (
          value.nil? &&
          required?(property) &&
          (
            !self.class._readonly_property?(property) ||
            !allow_leaving_required_readonly_properties_blank?
          )
        )
          fail_property_required_error!(property)
        end
      end

      # Override Hashie to allow a readonly attribute to have a default of nil
      def assert_property_set!(property)
        if (
          send(property).nil? &&
          required?(property) &&
          (
            !self.class._readonly_property?(property) ||
            !allow_leaving_required_readonly_properties_blank?
          )
        )
          fail_property_required_error!(property)
        end
      end

      # Override CustomCoercion to pass along self to coercer to account for
      # overriding the readonly requirement in #==
      def fetch_coercion(into)
        self.class.fetch_coercion(into, self)
      end

      def allow_writing_readonly_properties?
        @allow_writing_readonly_properties
      end

      def allow_leaving_required_readonly_properties_blank?
        @allow_leaving_required_readonly_properties_blank
      end

      def readonly_attributes
        self.class.readonly_properties.inject({}) do |hash, name|
          hash.merge(name => public_send(name))
        end
      end
    end
  end
end
