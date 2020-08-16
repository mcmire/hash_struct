require "active_support/core_ext/module/delegation"
require "bigdecimal"
require "time"
require "active_support/core_ext/object/json"

require "hash_struct/deep_transform"
require "hash_struct/error"
require "hash_struct/hashie_extensions"
require "hash_struct/types"

class HashStruct < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  # Order-independent mixins
  include HashieExtensions::AsJson
  include HashieExtensions::AttributeMethods
  include HashieExtensions::CustomErrorMessages
  include HashieExtensions::DescribeProperty
  include HashieExtensions::DiscardAllUnrecognizedAttributes
  include HashieExtensions::Equality
  include HashieExtensions::Inspect
  include HashieExtensions::ToH

  # Order-dependent mixins
  include HashieExtensions::CustomCoercion
  include HashieExtensions::AfterWritingAttribute
  include HashieExtensions::ResolveProperty
  include HashieExtensions::DefaultPropertiesToRequired
  include HashieExtensions::TransformPropertyNames
  include HashieExtensions::Aliases
  include HashieExtensions::BooleanPropertiesAllowNil
  include HashieExtensions::ReadonlyProperties
end
