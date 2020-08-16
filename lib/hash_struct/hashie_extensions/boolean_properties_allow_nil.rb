class HashStruct
  module HashieExtensions
    module BooleanPropertiesAllowNil
      private

      # Override Hashie to NOT remove nil values, so that boolean properties can
      # be set to nil
      def initialize_attributes(attributes)
        return unless attributes
        update_attributes(attributes)
      end

      # Override CustomCoercion to not ignore value if it is nil, to account for
      # boolean properties being set to nil
      def should_coerce?(value, into)
        !into.nil?
      end
    end
  end
end
