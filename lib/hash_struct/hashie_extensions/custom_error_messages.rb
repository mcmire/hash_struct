class HashStruct
  module HashieExtensions
    module CustomErrorMessages
      private

      # Override Hashie to use a different message
      def fail_property_required_error!(property)
        raise_error!(
          "Required property #{self.class._describe_property(property)} " +
          "was missing or set to nil."
        )
      end

      # Override Hashie to use a different message
      def fail_no_property_error!(property)
        raise_error!("Unrecognized property #{property.inspect}.")
      end

      def raise_error!(message)
        raise Error.new("(#{self.class.name}) #{message}")
      end
    end
  end
end
