require "hash_struct/version"

require "active_support/core_ext/module/delegation"
require "bigdecimal"
require "time"
require "active_support/core_ext/object/json"

class HashStruct
  module Types
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
        value.to_s
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
    property = self.class.look_up_property!(name)

    if property
      if property.readonly? && !override && !allow_writing_readonly_attributes?
        raise Error.new(
          "(#{self.class.name}) Couldn't write readonly attribute " +
          "#{name.inspect}."
        )
      else
        coerced_value =
          if property.coerce && (!value.nil? || property.coerce == :boolean)
            coerce(value, property.coerce, property)
          else
            value
          end

        if property.required? && coerced_value.nil? && property.coerce != :boolean
          inspected_aliases =
            if property.aliases.any?
              ' (' + property.aliases.map(&:inspect).join(', ') + ')'
            else
              ''
            end

          raise Error.new(
            "(#{self.class.name}) Required property #{property.name.inspect}" +
            "#{inspected_aliases} was missing or set to nil."
          )
        end

        written_attributes[property.name] = coerced_value

        property.after_write_callbacks.each do |callback|
          instance_exec(written_attributes[property.name], &callback)
        end
      end
    else
      raise Error.new(
        "#{self.class.name} tried to write a property #{name.inspect} " +
        "that it doesn't recognize."
      )
    end
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
    Helpers.process_hash_structs_at_and_within(
      serializable_attributes,
      on_hash_struct: :serialize,
      always: :as_json
    )
  end

  def to_h
    Helpers.process_hash_structs_at_and_within(
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

  def allow_writing_readonly_attributes?
    @allow_writing_readonly_attributes
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
        inspected_aliases =
          if property.aliases.any?
            ' (' + property.aliases.map(&:inspect).join(', ') + ')'
          else
            ''
          end

        raise Error.new(
          "(#{self.class.name}) Required property #{property.name.inspect}" +
          "#{inspected_aliases} was missing or set to nil."
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
    coerce_without_exceptions(value, coercer)
  rescue => error
    message = "(#{self.class.name}) Could not coerce #{value.inspect} for"

    if property.required?
      message << ' required property'
    else
      message << ' property'
    end

    message << " #{property.name.inspect}"

    if coercer.respond_to?(:call)
      message << ' using a custom proc'
    elsif coercer.is_a?(Class)
      message << " using #{coercer.name}"
    elsif coercer.is_a?(Array)
      message << " using Array[#{coercer.first.inspect}]"
    elsif coercer.is_a?(Hash)
      key_and_value =
        "#{coercer.keys.first.inspect} => #{coercer.values.first.inspect}"
      message << " using Hash[#{key_and_value}]"
    else
      message << " using #{coercer.inspect}"
    end

    message << ": #{error.message} (#{error.class})"

    raise Error, message, cause: error
  end

  def coerce_without_exceptions(value, coercer)
    if coercer.is_a?(Symbol)
      if respond_to?(coercer, true)
        send(coercer, value)
      else
        coerce_without_exceptions(value, BUILTIN_TYPES.fetch(coercer))
      end
    elsif coercer.is_a?(Array)
      coerce_array(value, coercer.first)
    elsif coercer.is_a?(Hash)
      coerce_hash(value, coercer.keys.first, coercer.values.first)
    elsif coercer.respond_to?(:call)
      coerce_with_callable(value, coercer)
    else
      coerce_with_class(value, coercer)
    end
  end

  def coerce_array(array, coercer)
    array.map { |value| coerce_without_exceptions(value, coercer) }
  end

  def coerce_hash(hash, key_coercer, value_coercer)
    hash.inject({}) do |coerced_hash, (key, value)|
      coerced_key = coerce_without_exceptions(key, key_coercer)
      coerced_value = coerce_without_exceptions(value, value_coercer)
      coerced_hash.merge(coerced_key => coerced_value)
    end
  end

  def coerce_with_callable(value, callable)
    callable.call(value)
  end

  def coerce_with_class(value, klass, *args)
    if klass.respond_to?(:coerce)
      klass.coerce(value)
    elsif klass.ancestors.include?(HashStruct)
      klass.new(
        value,
        _allow_writing_readonly_attributes: allow_writing_readonly_attributes?
      )
    else
      klass.new(value)
    end
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

  class Error < StandardError; end

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
  private_constant :Helpers
end
