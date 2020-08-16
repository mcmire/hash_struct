class HashStruct
  module HashieExtensions
    module Inspect
      def inspect
        sorted_keys_and_values = _full_attributes.keys.sort.map do |k|
          "#{k}: #{_full_attributes[k].inspect}"
        end

        "#<%s %s>" % [self.class.name, sorted_keys_and_values.join(', ')]
      end
      alias_method :to_s, :inspect
    end
  end
end
