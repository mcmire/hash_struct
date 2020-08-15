require "hash_struct/version"

require "active_support/core_ext/module/delegation"
require "bigdecimal"
require "time"
require "active_support/core_ext/object/json"

require "hash_struct/class_methods"
require "hash_struct/coerce"
require "hash_struct/error"
require "hash_struct/instance_methods"
require "hash_struct/process_hash_structs_at_and_within"
require "hash_struct/property"
require "hash_struct/types"
require "hash_struct/write_attribute"

class HashStruct
  include InstanceMethods
  extend ClassMethods

  def self.inherited(subclass)
    subclass.properties = properties.dup
    subclass.attribute_methods_module = Module.new
    subclass.send(:include, subclass.attribute_methods_module)
    subclass.transform_property_names = transform_property_names
    subclass.discard_all_unrecognized_attributes = discard_all_unrecognized_attributes?
  end

  self.properties = Set.new
  self.transform_property_names = -> (name) { name.to_sym }
  self.discard_all_unrecognized_attributes = false
end
