class HashStruct
  class WriteAttribute
    def self.call(hash_struct, name, value, override:)
      new(hash_struct, name, value, override: override).call
    end

    def initialize(hash_struct, name, value, override:)
      @hash_struct = hash_struct
      @name = name
      @value = value
      @override = override
    end

    def call
      recognize_property!
      ensure_writeable_property!
      ensure_required_property_present!

      write_attribute
      fire_after_write_callbacks
    end

    private

    attr_reader :hash_struct, :name, :value

    def override?
      @override
    end

    def recognize_property!
      if !property
        raise Error.new(
          "#{hash_struct.class.name} tried to write a property #{name.inspect} " +
          "that it doesn't recognize."
        )
      end
    end

    def ensure_writeable_property!
      if cannot_write_readonly_attribute?
        raise Error.new(
          "(#{hash_struct.class.name}) Couldn't write readonly attribute " +
          "#{name.inspect}."
        )
      end
    end

    def cannot_write_readonly_attribute?
      property.readonly? &&
        !override? &&
        !hash_struct.allow_writing_readonly_attributes?
    end

    def ensure_required_property_present!
      if required_property_blank?
        raise Error.new(
          "(#{hash_struct.class.name}) Required property #{property.name.inspect}" +
          "#{property.inspected_aliases} was missing or set to nil."
        )
      end
    end

    def required_property_blank?
      property.required? &&
        coerced_value.nil? &&
        property.coerce != :boolean
    end

    def should_coerce_value?
      property.coerce && (!value.nil? || property.coerce == :boolean)
    end

    def write_attribute
      hash_struct.written_attributes[property.name] = coerced_value
    end

    def coerced_value
      if should_coerce_value?
        Coerce.call(
          class_name: hash_struct.class.name,
          value: value,
          coercer: property.coerce,
          property: property,
          allow_writing_readonly_attributes: hash_struct.allow_writing_readonly_attributes?
        )
      else
        value
      end
    end

    def fire_after_write_callbacks
      property.after_write_callbacks.each do |callback|
        hash_struct.instance_exec(
          hash_struct.written_attributes[property.name],
          &callback
        )
      end
    end

    def property
      @property ||= hash_struct.class.look_up_property!(name)
    end
  end
end
