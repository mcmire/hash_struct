class HashStruct
  class Property
    attr_reader :name, :aliases, :default, :coerce, :block,
      :after_write_callbacks

    def initialize(
      name:,
      required:,
      aliases:,
      default:,
      readonly:,
      reader: name,
      coerce:,
      block:
    )
      @name = name
      @required = required
      @aliases = aliases
      @default = default
      @readonly = readonly
      @reader = reader
      @coerce = coerce
      @block = block

      @after_write_callbacks = []
    end

    def update(overrides)
      overrides.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def required?
      @required
    end

    def readonly?
      @readonly
    end

    def ==(other)
      other.is_a?(self.class) && name == other.name
    end
    alias_method :eql?, :==

    def hash
      name.hash
    end
  end
end
