class HashStruct
  module InstanceMethods
    def self.included(base)
      base.class_eval do
        delegate(
          :dig,
          :each_pair,
          :fetch,
          :keys,
          :include?,
          :slice,
          to: :full_attributes
        )

        attr_reader :written_attributes
        attr_reader :original_attributes
      end
    end

    def initialize(*args)
      if args.size == 2
        hash_struct_or_attributes, options = args
      else
        hash_struct_or_attributes = args.first || {}
        options = {}
      end

      @allow_reading_readonly_attributes =
        options.fetch(:_allow_reading_readonly_attributes, false)
      @allow_writing_readonly_attributes =
        options.fetch(:_allow_writing_readonly_attributes, false)

      if hash_struct_or_attributes.is_a?(self.class)
        @written_attributes = hash_struct_or_attributes.send(:written_attributes)
      else
        @original_attributes = hash_struct_or_attributes
        @written_attributes = {}
        assign_attributes(default_attributes.merge(hash_struct_or_attributes))
        ensure_required_properties_set!
      end
    end

    def allow_writing_readonly_attributes?
      @allow_writing_readonly_attributes
    end

    def attributes
      self.class.writable_properties.inject({}) do |hash, property|
        hash.merge(property.name => read_attribute(property.name))
      end
    end

    def read_attribute(name)
      property = self.class.look_up_property!(name)

      if property
        if property.readonly? && !allow_reading_readonly_attributes? && property.block
          instance_eval(&property.block)
        else
          written_attributes[property.name]
        end
      else
        raise Error.new(
          "(#{self.class.name}) Couldn't read unrecognized property " +
          "#{name.inspect}."
        )
      end
    end
    alias_method :[], :read_attribute

    def write_attribute(name, value, override: false)
      WriteAttribute.call(self, name, value, override: override)
    end
    alias_method :[]=, :write_attribute

    def merge(given_attributes)
      self.class.new(attributes.merge(given_attributes))
    end

    def inspect
      sorted_keys_and_values = full_attributes.keys.sort.map do |k|
        "#{k}: #{full_attributes[k].inspect}"
      end

      "#<%s %s>" % [self.class.name, sorted_keys_and_values.join(', ')]
    end
    alias_method :to_s, :inspect

    def serialize
      ProcessHashStructsAtAndWithin.(
        serializable_attributes,
        on_hash_struct: :serialize,
        always: :as_json
      )
    end

    def to_h
      ProcessHashStructsAtAndWithin.(
        serializable_attributes,
        on_hash_struct: :to_h
      )
    end

    def as_json(_options = {})
      serialize
    end

    def ==(other)
      if other.is_a?(Hash)
        container = self.class.new(
          other,
          _allow_writing_readonly_attributes: true,
          _allow_reading_readonly_attributes: true
        )
        self == container &&
          readonly_attributes == container.send(:readonly_attributes)
      elsif other.is_a?(self.class)
        full_attributes == other.send(:full_attributes)
      else
        false
      end
    rescue Error
      false
    end

    def pretty_print(pp)
      attribute_names = full_attributes.keys.sort

      pp.object_group(self) do
        pp.seplist(attribute_names, -> { pp.text ',' }) do |attribute_name|
          pp.breakable ' '
          pp.group(1) do
            pp.text attribute_name.to_s
            pp.text ':'
            pp.breakable
            pp.pp full_attributes[attribute_name]
          end
        end
      end
    end

    def attributes_for_super_diff
      serializable_attributes
    end

    protected

    def assign_attributes(attributes)
      attributes.each do |name, value|
        unless self.class.discard_within_mass_assignment?(name)
          write_attribute(name, value)
        end
      end
    end

    def serializable_attributes
      writable_and_readonly_attributes
    end

    private

    def allow_reading_readonly_attributes?
      @allow_reading_readonly_attributes
    end

    def standardize_property_names_in!(attributes)
      attributes.inject({}) do |hash, (name, value)|
        property = self.class.look_up_property!(name)
        hash.merge(property.name => value)
      end
    end

    def ensure_required_properties_set!
      self.class.required_properties.each do |property|
        if read_attribute(property.name).nil?
          raise Error.new(
            "(#{self.class.name}) Required property #{property.name.inspect}" +
            "#{property.inspected_aliases} was missing or set to nil."
          )
        end
      end
    end

    def default_attributes
      self.class.writable_properties.inject({}) do |hash, property|
        if property.default
          hash.merge(property.name => property.default)
        else
          hash
        end
      end
    end

    def coerce(value, coercer, property)
      Coerce.call(
        class_name: self.class.name,
        value: value,
        coercer: coercer,
        property: property,
        allow_writing_readonly_attributes: allow_writing_readonly_attributes?
      )
    end

    def full_attributes
      self.class.properties.inject({}) do |hash, property|
        non_alias_attributes = { property.name => read_attribute(property.name) }

        alias_attributes =
          property.aliases.inject({}) do |hash2, alias_name|
            hash2.merge(alias_name => read_attribute(alias_name))
          end

        hash
          .merge(non_alias_attributes)
          .merge(alias_attributes)
      end
    end

    def readonly_attributes
      self.class.readonly_properties.inject({}) do |hash, property|
        hash.merge(property.name => read_attribute(property.name))
      end
    end

    def writable_and_readonly_attributes
      self.class.properties.inject({}) do |hash, property|
        hash.merge(property.name => read_attribute(property.name))
      end
    end
  end
end
