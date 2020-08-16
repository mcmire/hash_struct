class HashStruct
  module Types
    def self.class_for(type)
      BUILTIN_TYPES[type]
    end

    module Array
      def self.coerce(value)
        Array(value)
      end
    end

    module BigDecimal
      def self.coerce(value)
        BigDecimal(value)
      end
    end

    module Boolean
      def self.coerce(value)
        !!value
      end
    end

    module Float
      def self.coerce(value)
        Float(value)
      end
    end

    module Integer
      def self.coerce(value)
        Integer(value)
      end
    end

    module NonBlankString
      def self.coerce(value)
        if value.to_s.empty?
          nil
        else
          value.to_s
        end
      end
    end

    module String
      def self.coerce(value)
        if !value.nil?
          value.to_s
        end
      end
    end

    module Symbol
      def self.coerce(value)
        value.to_sym
      end
    end

    module TimeInUtc
      def self.coerce(value)
        if acts_like_time?(value)
          value.to_time.utc
        elsif acts_like_date?(value)
          date = value.to_date
          Time.utc(date.year, date.month, date.day)
        else
          begin
            coerce(Time.iso8601(value))
          rescue ArgumentError
            coerce(Date.iso8601(value))
          end
        end
      end

      def self.acts_like_time?(value)
        (value.respond_to?(:acts_like_time?) && value.acts_like_time?) ||
          value.is_a?(Time) ||
          value.is_a?(DateTime)
      end

      def self.acts_like_date?(value)
        (value.respond_to?(:acts_like_date?) && value.acts_like_date?) ||
          value.is_a?(Date) ||
          value.is_a?(DateTime)
      end
    end
  end

  BUILTIN_TYPES = {
    array: Types::Array,
    big_decimal: Types::BigDecimal,
    boolean: Types::Boolean,
    float: Types::Float,
    integer: Types::Integer,
    non_blank_string: Types::NonBlankString,
    string: Types::String,
    symbol: Types::Symbol,
    time_in_utc: Types::TimeInUtc
  }
end
