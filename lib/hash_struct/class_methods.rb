class HashStruct
  module ClassMethods
    def self.extended(base)
      base.singleton_class.class_eval do
        attr_accessor :properties
        attr_accessor :attribute_methods_module
        attr_writer :transform_property_names
        attr_writer :discard_all_unrecognized_attributes
      end
    end

    def discard_all_unrecognized_attributes?
      @discard_all_unrecognized_attributes
    end

    def property(name, options = {}, &block)
      name = transform_property_names.call(name)
      aliases = options.fetch(:aliases, []).map(&transform_property_names)
      coerce = options[:coerce]
      default = options[:default]
      reader = options.fetch(:reader, name)
      required = options.fetch(:required, true)
      readonly = options[:readonly]

      property = look_up_property(name)

      if property
        property.update(options, &block)
      else
        property = Property.new(
          name: name,
          required: required,
          aliases: aliases,
          default: default,
          readonly: readonly,
          reader: reader,
          coerce: coerce,
          block: block
        )
        properties << property
      end

      attribute_methods_module.module_eval do
        if method_defined?(reader)
          remove_method(reader)
        end

        if block
          define_method(reader, &block)
        else
          define_method(reader) do
            read_attribute(name)
          end
        end

        if !readonly
          define_method("#{name}=") do |value|
            write_attribute(name, value)
          end
        end
      end

      aliases.each do |alias_name|
        alias_property(alias_name, name, readonly: readonly)
      end
    end

    def alias_property(different_name, original_name, readonly: false)
      attribute_methods_module.module_eval do
        if method_defined?(different_name)
          remove_method(different_name)
        end

        define_method(different_name) { public_send(original_name) }

        if !readonly
          if method_defined?("#{different_name}=")
            remove_method("#{different_name}=")
          end

          define_method("#{different_name}=") do |value|
            public_send("#{original_name}=", value)
          end
        end
      end
    end

    def transform_property_names(&block)
      if block
        @transform_property_names = block
      else
        @transform_property_names
      end
    end

    def after_writing_attribute(property_name, &callback)
      look_up_property!(property_name).after_write_callbacks << callback
    end

    def look_up_property(name)
      name = transform_property_names.call(name)

      properties.detect do |prop|
        prop.name == name || prop.aliases.include?(name)
      end
    end

    def look_up_property!(name)
      property = look_up_property(name)

      if property
        property
      else
        raise Error.new(
          "(#{self.name}) Unrecognized property #{name.inspect}."
        )
      end
    end

    def has_property?(name)
      look_up_property(name).present?
    end

    def discard_within_mass_assignment?(name)
      discard_all_unrecognized_attributes? && !has_property?(name)
    end

    def required_properties
      writable_properties.select(&:required?)
    end

    def readonly_properties
      properties.select(&:readonly?)
    end

    def writable_properties
      properties.reject(&:readonly?)
    end
  end
end
