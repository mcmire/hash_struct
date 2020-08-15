module Helpers
  def instantiate_model_via(way_to_write, model, attributes, defaults = {})
    if way_to_write == :initializer
      model.new(attributes)
    else
      default_attributes = default_attributes_for(
        model,
        defaults,
        property_names: attributes.keys
      )
      instance = model.new(default_attributes)

      attributes.each do |name, value|
        instance.send(way_to_write, name, value)
      end

      instance
    end
  end

  def default_attributes_for(
    model,
    defaults,
    property_names: model.properties.map(&:name)
  )
    property_names.inject({}) do |hash, name|
      property = model.look_up_property!(name)

      if property.required?
        default_value = determine_default_for(
          property.coerce,
          name: name,
          defaults: defaults
        )
        hash.merge(name => default_value)
      else
        hash
      end
    end
  end

  def determine_default_for(coerce, name: nil, defaults: {})
    if defaults.include?(name)
      defaults[name]
    elsif (
      coerce &&
      coerce.is_a?(Class) &&
      coerce.ancestors.include?(described_class)
    )
      coerce.new(default_attributes_for(coerce, defaults))
    else
      case coerce
      when Array
        [determine_default_for(coerce.first)]
      when Hash
        default_key = determine_default_for(coerce.keys.first)
        default_value = determine_default_for(coerce.values.first)
        { default_key => default_value }
      when :big_decimal, :float, :integer
        0
      when :boolean
        true
      when :symbol
        :some_value
      when :time_in_utc
        '2020-01-01T00:00:00.000Z'
      else
        'some value'
      end
    end
  end

  def read_attribute_via(way_to_read, instance, attribute_name)
    if way_to_read == :method
      instance.send(attribute_name)
    else
      instance.send(way_to_read, attribute_name)
    end
  end

  def define_model(name = :TestHashStruct, &block)
    define_class(name, superclass: described_class, &block)
  end

  def define_class(name, superclass: nil, &block)
    args = [superclass].compact

    Class.new(*args) do
      singleton_class.class_eval do
        define_method(:name) { name.to_s }
      end

      if block
        class_eval(&block)
      end
    end
  end
end
