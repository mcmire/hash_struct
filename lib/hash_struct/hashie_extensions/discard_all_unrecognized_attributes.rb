class HashStruct
  module HashieExtensions
    module DiscardAllUnrecognizedAttributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def discard_all_unrecognized_attributes=(value)
          if value
            include Hashie::Extensions::IgnoreUndeclared
          end
        end
      end
    end
  end
end
