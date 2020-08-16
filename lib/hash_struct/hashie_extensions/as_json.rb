class HashStruct
  module HashieExtensions
    module AsJson
      def as_json(*)
        DeepTransform.(
          _full_attributes,
          transform_keys: :as_json,
          transform_values: :as_json
        )
      end
      alias_method :serialize, :as_json
    end
  end
end
