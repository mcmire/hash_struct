RSpec::Matchers.define :reject_writing_attribute do |attribute_name|
  chain :with_default, :default_value
  chain :to, :input
  chain :via, :way_to_write
  chain :with, :expected_error_class, :expected_error_message

  attr_reader :model, :matcher

  match do |model|
    @model = model
    @matcher = raise_error(expected_error_class, expected_error_message)
    matcher.matches?(assigning_attribute)
  end

  failure_message do
    matcher.failure_message
  end

  define_method(:assigning_attribute) do
    lambda do
      instantiate_model_via(
        way_to_write,
        model,
        { attribute_name => input } ,
        defaults
      )
    end
  end

  define_method(:defaults) do
    if default_value
      { attribute_name => default_value }
    else
      {}
    end
  end
end
