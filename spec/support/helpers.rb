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

  def default_attributes_for(model, defaults, property_names: model.properties)
    property_names.inject({}) do |hash, name|
      if model.required_properties.include?(name)
        default_value = determine_default_for(
          model.key_coercion(name),
          name: name,
          defaults: defaults
        )
        hash.merge(name => default_value)
      else
        hash
      end
    end
  end

  def determine_default_for(coercion, name: nil, defaults: {})
    if defaults.include?(name)
      defaults[name]
    elsif (
      coercion &&
      coercion.is_a?(Class) &&
      coercion.ancestors.include?(described_class)
    )
      coercion.new(default_attributes_for(coercion, defaults))
    else
      case coercion
      when Array
        [determine_default_for(coercion.first)]
      when Hash
        default_key = determine_default_for(coercion.keys.first)
        default_value = determine_default_for(coercion.values.first)
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
    define_class(name, superclass: HashStruct, &block)
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
