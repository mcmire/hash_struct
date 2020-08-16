class HashStruct
  module HashieExtensions
    module TransformPropertyNames
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def transform_property_names(&block)
          @property_name_transformer = block
        end

        # Override to property_name_transformer
        def _resolve_property(name)
          property_name_transformer.call(super)
        end

        def _describe_property(name)
          super(property_name_transformer.call(name))
        end

        private

        def property_name_transformer
          @property_name_transformer ||= -> (name) { name.to_sym }
        end
      end
    end
  end
end
