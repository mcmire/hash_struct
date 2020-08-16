class HashStruct
  module HashieExtensions
    module Equality
      def _wrap(value, with: self.class)
        with.new(value)
      end

      def ==(other)
        if other.is_a?(self.class)
          _full_attributes == other._full_attributes
        else
          _full_attributes == _wrap(other)
        end
      rescue
        false
      end
    end
  end
end
