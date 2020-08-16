class HashStruct
  module HashieExtensions
    module CustomCoercion
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method :[]=, :set_value_with_coercion
        end
      end

      module ClassMethods
        # Override Hashie to use our coercion types instead of Hashie's builtin
        # types
        def build_coercion(type)
          type_class = Types.class_for(type)

          if type_class
            build_coercion(type_class)
          elsif type.is_a?(Class)
            if type.respond_to?(:coerce)
              -> (value) { type.coerce(value) }
            elsif type.ancestors.include?(HashStruct)
              build_coercion_for_hash_struct(type)
            else
              -> (value) do
                if value.is_a?(type)
                  value
                else
                  type.new(value)
                end
              end
            end
          else
            super
          end
        end
      end

      # Override Hashie to:
      # - customize coercion error message
      # - rescue any error, not just NoMethodError and TypeError
      # - provide an extension point for future mixins around fetching coercion
      #
      # NOTE: We are overriding #set_value_with_coercion instead of #[]= here
      # because that's how Hashie does it.
      def set_value_with_coercion(key, value)
        into = self.class.key_coercion(key) || self.class.value_coercion(value)
        new_value = value

        if should_coerce?(value, into)
          begin
            new_value = fetch_coercion(into).call(value)
          rescue => error
            raise_coercion_error!(key, value, into, error)
          end
        end

        set_value_without_coercion(key, new_value)
      end

      private

      def should_coerce?(value, into)
        !value.nil? && !into.nil?
      end

      def fetch_coercion(into)
        self.class.fetch_coercion(into)
      end

      def build_coercion_for_hash_struct(type)
        -> (value, hash_struct) do
          hash_struct._wrap(value, with: type)
        end
      end

      def raise_coercion_error!(property_name, value, type, original_error)
        message = "Could not coerce #{value.inspect} for"

        if required?(property_name)
          message << ' required property'
        else
          message << ' property'
        end

        message << " #{property_name.inspect}"

        if type.respond_to?(:call)
          message << ' using a custom proc'
        elsif type.is_a?(Class)
          message << " using #{type.name}"
        elsif type.is_a?(Array)
          message << " using Array[#{type.first.inspect}]"
        elsif type.is_a?(Hash)
          key_and_value =
            "#{type.keys.first.inspect} => #{type.values.first.inspect}"
          message << " using Hash[#{key_and_value}]"
        else
          message << " using #{type.inspect}"
        end

        message << ": #{original_error.message} (#{original_error.class})"

        raise_error!(message)
      end
    end
  end
end
