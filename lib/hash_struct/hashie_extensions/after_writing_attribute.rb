class HashStruct
  module HashieExtensions
    module AfterWritingAttribute
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method :set_value_without_after_writing_attribute, :[]=
          alias_method :[]=, :set_value_with_after_writing_attribute
        end
      end

      module ClassMethods
        def after_writing_attribute(property_name, &block)
          (after_write_callbacks[property_name] ||= []) << block
        end

        def _after_write_callbacks_for(name)
          after_write_callbacks.fetch(name, [])
        end

        private

        def after_write_callbacks
          @after_write_callbacks ||= {}
        end
      end

      # Override Hashie to call callbacks after writing attribute
      def set_value_with_after_writing_attribute(name, value)
        set_value_without_after_writing_attribute(name, value).tap do
          self.class._after_write_callbacks_for(name).each do |callback|
            instance_exec(self[name], &callback)
          end
        end
      end
    end
  end
end
