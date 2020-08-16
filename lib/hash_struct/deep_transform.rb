class HashStruct
  class DeepTransform
    IDENTITY = -> (x) { x }

    def self.call(
      transformable,
      transform_keys: IDENTITY,
      transform_values: IDENTITY,
      **rest
    )
      new(
        transformable,
        transform_keys: transform_keys,
        transform_values: transform_values
      ).call
    end

    def initialize(transformable, transform_keys:, transform_values:)
      @transformable = transformable
      @transform_keys = transform_keys
      @transform_values = transform_values
    end

    def call
      if transformable.is_a?(Hash)
        transformable.inject({}) do |hash, (key, value)|
          transformed_key = transform(key, transform_keys)
          transformed_value = self.class.call(
            value,
            transform_keys: transform_keys,
            transform_values: transform_values
          )
          hash.merge(transformed_key => transformed_value)
        end
      elsif transformable.is_a?(Array)
        transformable.map do |item|
          self.class.call(
            item,
            transform_keys: transform_keys,
            transform_values: transform_values
          )
        end
      else
        transform(transformable, transform_values)
      end
    end

    private

    attr_reader :transformable, :transform_keys, :transform_values

    def transform(transformable, transformer, *args)
      if transformer.respond_to?(:call)
        transformer.call(transformable, *args)
      else
        transformable.public_send(transformer, *args)
      end
    end
  end
end
