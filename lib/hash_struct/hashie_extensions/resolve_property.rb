class HashStruct
  module HashieExtensions
    module ResolveProperty
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method :set_value_without_resolve_property, :[]=
          alias_method :[]=, :set_value_with_resolve_property
        end
      end

      module ClassMethods
        # Override Hashie so that how properties are resolved can be overridden
        # later (e.g. symbol keys, aliases, etc.)
        def property(name, options = {}, &block)
          _resolve_property(name).tap do |resolved_property|
            super(resolved_property, options, &block)
          end
        end

        def _resolve_property(name)
          name
        end
      end

      # Override Hashie so that how properties are resolved can be overridden
      # later (e.g. symbol keys, aliases, etc.)
      def [](name)
        super(self.class._resolve_property(name))
      end

      # Override Hashie so that how properties are resolved can be overridden
      # later (e.g. symbol keys, aliases, etc.)
      def set_value_with_resolve_property(name, value)
        set_value_without_resolve_property(
          self.class._resolve_property(name),
          value
        )
      end
    end
  end
end
