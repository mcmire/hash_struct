class HashStruct
  module HashieExtensions
    module DescribeProperty
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def _describe_property(name)
          name.inspect
        end
      end
    end
  end
end
