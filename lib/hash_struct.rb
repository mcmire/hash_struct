require "hash_struct/version"

require "active_support/core_ext/module/delegation"
require "bigdecimal"
require "time"
require "active_support/core_ext/object/json"

require "hash_struct/coerce"
require "hash_struct/error"
require "hash_struct/process_hash_structs_at_and_within"
require "hash_struct/property"
require "hash_struct/types"
require "hash_struct/write_attribute"

class HashStruct
  class << self
    attr_accessor :properties
    attr_accessor :attribute_methods_module
    attr_writer :transform_property_names
    attr_writer :discard_all_unrecognized_attributes

    def discard_all_unrecognized_attributes?
      @discard_all_unrecognized_attributes
    end

    def inherited(subclass)
      subclass.properties = properties.dup
      subclass.attribute_methods_module = Module.new
      subclass.send(:include, subclass.attribute_methods_module)
      subclass.transform_property_names = transform_property_names
      subclass.discard_all_unrecognized_attributes = discard_all_unrecognized_attributes?
    end

    def property(name, options = {}, &block)
      name = transform_property_names.call(name)
      aliases = options.fetch(:aliases, []).map(&transform_property_names)
      coerce = options[:coerce]
      default = options[:default]
      reader = options.fetch(:reader, name)
      required = options.fetch(:required, true)
      readonly = options[:readonly]

      property = look_up_property(name)

      if property
        property.update(options, &block)
      else
        property = Property.new(
          name: name,
          required: required,
          aliases: aliases,
          default: default,
          readonly: readonly,
          reader: reader,
          coerce: coerce,
          block: block
        )
        properties << property
      end

      attribute_methods_module.module_eval do
        if method_defined?(reader)
          remove_method(reader)
        end

        if block
          define_method(reader, &block)
        else
          define_method(reader) do
            read_attribute(name)
          end
        end

        if !readonly
          define_method("#{name}=") do |value|
            write_attribute(name, value)
          end
        end
      end

      aliases.each do |alias_name|
        alias_property(alias_name, name, readonly: readonly)
      end
    end

    def alias_property(different_name, original_name, readonly: false)
      attribute_methods_module.module_eval do
        if method_defined?(different_name)
          remove_method(different_name)
        end

        define_method(different_name) { public_send(original_name) }

        if !readonly
          if method_defined?("#{different_name}=")
            remove_method("#{different_name}=")
          end

          define_method("#{different_name}=") do |value|
            public_send("#{original_name}=", value)
          end
        end
      end
    end

    def transform_property_names(&block)
      if block
        @transform_property_names = block
      else
        @transform_property_names
      end
    end

    def after_writing_attribute(property_name, &callback)
      look_up_property!(property_name).after_write_callbacks << callback
    end

    def look_up_property(name)
      name = transform_property_names.call(name)

      properties.detect do |prop|
        prop.name == name || prop.aliases.include?(name)
      end
    end

    def look_up_property!(name)
      property = look_up_property(name)

      if property
        property
      else
        raise Error.new(
          "(#{self.name}) Unrecognized property #{name.inspect}."
        )
      end
    end

    def has_property?(name)
      look_up_property(name).present?
    end

    def discard_within_mass_assignment?(name)
      discard_all_unrecognized_attributes? && !has_property?(name)
    end

    def required_properties
      writable_properties.select(&:required?)
    end

    def readonly_properties
      properties.select(&:readonly?)
    end

    def writable_properties
      properties.reject(&:readonly?)
    end
  end

  self.properties = Set.new
  self.transform_property_names = -> (name) { name.to_sym }
  self.discard_all_unrecognized_attributes = false

  delegate(
    :dig,
    :each_pair,
    :fetch,
    :keys,
    :include?,
    :slice,
    to: :full_attributes
  )

  attr_reader :written_attributes
  attr_reader :original_attributes

  def initialize(*args)
    if args.size == 2
      hash_struct_or_attributes, options = args
    else
      hash_struct_or_attributes = args.first || {}
      options = {}
    end

    @allow_reading_readonly_attributes =
      options.fetch(:_allow_reading_readonly_attributes, false)
    @allow_writing_readonly_attributes =
      options.fetch(:_allow_writing_readonly_attributes, false)

    if hash_struct_or_attributes.is_a?(self.class)
      @written_attributes = hash_struct_or_attributes.send(:written_attributes)
    else
      @original_attributes = hash_struct_or_attributes
      @written_attributes = {}
      assign_attributes(default_attributes.merge(hash_struct_or_attributes))
      ensure_required_properties_set!
    end
  end

  def allow_writing_readonly_attributes?
    @allow_writing_readonly_attributes
  end

  def attributes
    self.class.writable_properties.inject({}) do |hash, property|
      hash.merge(property.name => read_attribute(property.name))
    end
  end

  def read_attribute(name)
    property = self.class.look_up_property!(name)

    if property
      if property.readonly? && !allow_reading_readonly_attributes? && property.block
        instance_eval(&property.block)
      else
        written_attributes[property.name]
      end
    else
      raise Error.new(
        "(#{self.class.name}) Couldn't read unrecognized property " +
        "#{name.inspect}."
      )
    end
  end
  alias_method :[], :read_attribute

  def write_attribute(name, value, override: false)
    WriteAttribute.call(self, name, value, override: override)
  end
  alias_method :[]=, :write_attribute

  def merge(given_attributes)
    self.class.new(attributes.merge(given_attributes))
  end

  def inspect
    sorted_keys_and_values = full_attributes.keys.sort.map do |k|
      "#{k}: #{full_attributes[k].inspect}"
    end

    "#<%s %s>" % [self.class.name, sorted_keys_and_values.join(', ')]
  end
  alias_method :to_s, :inspect

  def serialize
    ProcessHashStructsAtAndWithin.(
      serializable_attributes,
      on_hash_struct: :serialize,
      always: :as_json
    )
  end

  def to_h
    ProcessHashStructsAtAndWithin.(
      serializable_attributes,
      on_hash_struct: :to_h
    )
  end

  def as_json(_options = {})
    serialize
  end

  def ==(other)
    if other.is_a?(Hash)
      container = self.class.new(
        other,
        _allow_writing_readonly_attributes: true,
        _allow_reading_readonly_attributes: true
      )
      self == container &&
        readonly_attributes == container.send(:readonly_attributes)
    elsif other.is_a?(self.class)
      full_attributes == other.send(:full_attributes)
    else
      false
    end
  rescue Error
    false
  end

  def pretty_print(pp)
    attribute_names = full_attributes.keys.sort

    pp.object_group(self) do
      pp.seplist(attribute_names, -> { pp.text ',' }) do |attribute_name|
        pp.breakable ' '
        pp.group(1) do
          pp.text attribute_name.to_s
          pp.text ':'
          pp.breakable
          pp.pp full_attributes[attribute_name]
        end
      end
    end
  end

  def attributes_for_super_diff
    serializable_attributes
  end

  protected

  def assign_attributes(attributes)
    attributes.each do |name, value|
      unless self.class.discard_within_mass_assignment?(name)
        write_attribute(name, value)
      end
    end
  end

  def serializable_attributes
    writable_and_readonly_attributes
  end

  private

  def allow_reading_readonly_attributes?
    @allow_reading_readonly_attributes
  end

  def standardize_property_names_in!(attributes)
    attributes.inject({}) do |hash, (name, value)|
      property = self.class.look_up_property!(name)
      hash.merge(property.name => value)
    end
  end

  def ensure_required_properties_set!
    self.class.required_properties.each do |property|
      if read_attribute(property.name).nil?
        raise Error.new(
          "(#{self.class.name}) Required property #{property.name.inspect}" +
          "#{property.inspected_aliases} was missing or set to nil."
        )
      end
    end
  end

  def default_attributes
    self.class.writable_properties.inject({}) do |hash, property|
      if property.default
        hash.merge(property.name => property.default)
      else
        hash
      end
    end
  end

  def coerce(value, coercer, property)
    Coerce.call(
      class_name: self.class.name,
      value: value,
      coercer: coercer,
      property: property,
      allow_writing_readonly_attributes: allow_writing_readonly_attributes?
    )
  end

  def full_attributes
    self.class.properties.inject({}) do |hash, property|
      non_alias_attributes = { property.name => read_attribute(property.name) }

      alias_attributes =
        property.aliases.inject({}) do |hash2, alias_name|
          hash2.merge(alias_name => read_attribute(alias_name))
        end

      hash
        .merge(non_alias_attributes)
        .merge(alias_attributes)
    end
  end

  def readonly_attributes
    self.class.readonly_properties.inject({}) do |hash, property|
      hash.merge(property.name => read_attribute(property.name))
    end
  end

  def writable_and_readonly_attributes
    self.class.properties.inject({}) do |hash, property|
      hash.merge(property.name => read_attribute(property.name))
    end
  end
end
