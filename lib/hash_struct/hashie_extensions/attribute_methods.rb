class HashStruct
  module HashieExtensions
    module AttributeMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def _writable_properties
          properties
        end
      end

      def read_attribute(*args, **options)
        self.[](*args, **options)
      end

      def write_attribute(*args, **options)
        self.[]=(*args, **options)
      end

      def attributes
        self.class._writable_properties.inject({}) do |hash, property_name|
          hash.merge(property_name => self[property_name])
        end
      end
      # NOTE: This is not quite the same thing as the old HashStruct, but very
      # very similar
      alias_method :written_attributes, :attributes

      def _full_attributes
        self.class.properties.inject({}) do |hash, property_name|
          hash.merge(property_name => self[property_name])
        end
      end
    end
  end
end
