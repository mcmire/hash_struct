class HashStruct
  module ProcessHashStructsAtAndWithin
    def self.call(value, on_hash_struct:, always: nil)
      if value.is_a?(HashStruct)
        call(
          value.send(on_hash_struct),
          on_hash_struct: on_hash_struct,
          always: always
        )
      elsif value.is_a?(Hash)
        value.inject({}) do |hash, (_key, _value)|
          _processed_key = call(
            _key,
            on_hash_struct: on_hash_struct,
            always: always
          )
          _processed_value = call(
            _value,
            on_hash_struct: on_hash_struct,
            always: always
          )
          hash.merge(_processed_key => _processed_value)
        end
      elsif value.is_a?(Array)
        value.map do |_value|
          call(
            _value,
            on_hash_struct: on_hash_struct,
            always: always
          )
        end
      elsif always
        value.send(always)
      else
        value
      end
    end
  end
end
