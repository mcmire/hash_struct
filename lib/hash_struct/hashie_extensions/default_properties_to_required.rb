class HashStruct
  module HashieExtensions
    module DefaultPropertiesToRequired
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Override Hashie
        def property(name, options = {}, &block)
          options = { required: true }.merge(options)
          required = options[:required]

          super(name, options, &block).tap do |resolved_name|
            if !required
              required_properties.delete(resolved_name)
            end
          end
        end
      end
    end
  end
end
