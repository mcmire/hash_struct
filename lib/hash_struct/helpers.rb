class HashStruct
  module Helpers
    def process_hash_structs_at_and_within(value, on_hash_struct:, always: nil)
      if value.is_a?(HashStruct)
        process_hash_structs_at_and_within(
          value.send(on_hash_struct),
          on_hash_struct: on_hash_struct,
          always: always
        )
      elsif value.is_a?(Hash)
        value.inject({}) do |hash, (_key, _value)|
          _processed_key = process_hash_structs_at_and_within(
            _key,
            on_hash_struct: on_hash_struct,
            always: always
          )
          _processed_value = process_hash_structs_at_and_within(
            _value,
            on_hash_struct: on_hash_struct,
            always: always
          )
          hash.merge(_processed_key => _processed_value)
        end
      elsif value.is_a?(Array)
        value.map do |_value|
          process_hash_structs_at_and_within(
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
    module_function :process_hash_structs_at_and_within
  end
end
