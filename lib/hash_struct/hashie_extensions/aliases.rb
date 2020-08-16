class HashStruct
  module HashieExtensions
    module Aliases
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Override Hashie to support aliases
        def property(name, options = {}, &block)
          options.fetch(:aliases, []).each do |alias_name|
            (aliases_by_property[name] ||= Set.new) << alias_name
            properties_by_alias[alias_name] = name

            define_getter_for(alias_name, property_name: name)
            define_setter_for(alias_name, property_name: name)
          end

          super(name, options, &block)
        end

        # Override Hashie to support aliases
        def define_getter_for(name, property_name: name)
          return if getters.include?(name)
          define_method(name) { |&block| self.[](property_name, &block) }
          getters << name
        end

        # Override Hashie to support aliases
        def define_setter_for(name, property_name: name)
          setter = :"#{name}="
          if !should_define_setter_for?(name, setter)
            define_method(setter) { |value| self.[]=(property_name, value) }
          end
        end

        # Override ResolveProperty to add aliases
        def _resolve_property(name)
          resolved_name = super(name)
          properties_by_alias.fetch(resolved_name, resolved_name)
        end

        # Override DescribeProperty to add aliases
        def _describe_property(name)
          resolved_name = _resolve_property(name)
          described_name = super(resolved_name)
          aliases = aliases_by_property.fetch(resolved_name, [])

          if aliases.any?
            "#{described_name} (#{aliases.map(&:inspect).join(', ')})"
          else
            "#{described_name}"
          end
        end

        private

        def properties_by_alias
          @properties_by_alias ||= {}
        end

        def aliases_by_property
          @aliases_by_property ||= {}
        end

        def should_define_setter_for?(name, setter)
          instance_methods.include?(setter)
        end
      end
    end
  end
end
