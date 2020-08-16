class HashStruct
  module HashieExtensions
    module ToH
      def to_h
        DeepTransform.(_full_attributes)
      end
    end
  end
end
