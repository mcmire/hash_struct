class HashStruct
  class Coerce
    def self.call(
      class_name:,
      value:,
      coercer:,
      property:,
      allow_writing_readonly_attributes:
    )
      new(
        class_name: class_name,
        value: value,
        coercer: coercer,
        property: property,
        allow_writing_readonly_attributes: allow_writing_readonly_attributes
      ).call
    end

    def initialize(
      class_name:,
      value:,
      coercer:,
      property:,
      allow_writing_readonly_attributes:
    )
      @class_name = class_name
      @value = value
      @coercer = coercer
      @property = property
      @allow_writing_readonly_attributes = allow_writing_readonly_attributes
    end

    def call
      coerce_without_exceptions(value, coercer)
    rescue => original_error
      raise_coercion_error!(original_error)
    end

    private

    attr_reader :class_name, :value, :coercer, :property

    def allow_writing_readonly_attributes?
      @allow_writing_readonly_attributes
    end

    def coerce_without_exceptions(value, coercer)
      if coercer.is_a?(Symbol)
        if respond_to?(coercer, true)
          send(coercer, value)
        else
          coerce_without_exceptions(value, BUILTIN_TYPES.fetch(coercer))
        end
      elsif coercer.is_a?(Array)
        coerce_array(value, coercer.first)
      elsif coercer.is_a?(Hash)
        coerce_hash(value, coercer.keys.first, coercer.values.first)
      elsif coercer.respond_to?(:call)
        coerce_with_callable(value, coercer)
      else
        coerce_with_class(value, coercer)
      end
    end

    def coerce_array(array, coercer)
      array.map { |value| coerce_without_exceptions(value, coercer) }
    end

    def coerce_hash(hash, key_coercer, value_coercer)
      hash.inject({}) do |coerced_hash, (key, value)|
        coerced_key = coerce_without_exceptions(key, key_coercer)
        coerced_value = coerce_without_exceptions(value, value_coercer)
        coerced_hash.merge(coerced_key => coerced_value)
      end
    end

    def coerce_with_callable(value, callable)
      callable.call(value)
    end

    def coerce_with_class(value, klass, *args)
      if klass.respond_to?(:coerce)
        klass.coerce(value)
      elsif klass.ancestors.include?(HashStruct)
        klass.new(
          value,
          _allow_writing_readonly_attributes: allow_writing_readonly_attributes?
        )
      else
        klass.new(value)
      end
    end

    def raise_coercion_error!(original_error)
      message = "(#{class_name}) Could not coerce #{value.inspect} for"

      if property.required?
        message << ' required property'
      else
        message << ' property'
      end

      message << " #{property.name.inspect}"

      if coercer.respond_to?(:call)
        message << ' using a custom proc'
      elsif coercer.is_a?(Class)
        message << " using #{coercer.name}"
      elsif coercer.is_a?(Array)
        message << " using Array[#{coercer.first.inspect}]"
      elsif coercer.is_a?(Hash)
        key_and_value =
          "#{coercer.keys.first.inspect} => #{coercer.values.first.inspect}"
        message << " using Hash[#{key_and_value}]"
      else
        message << " using #{coercer.inspect}"
      end

      message << ": #{original_error.message} (#{original_error.class})"

      raise Error, message, cause: original_error
    end
  end
end
