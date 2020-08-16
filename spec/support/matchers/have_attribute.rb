RSpec::Matchers.define :have_attribute do |attribute_name|
  attr_reader :model, :results

  chain :with_default, :default_value
  chain :that_maps, :values
  chain :reading_via, :way_to_read
  chain :writing_via, :way_to_write

  match do |model|
    @model = model

    results.all? do |result|
      result[:expected_output] == result[:actual_output]
    end
  end

  failure_message do
    "Expected #{model.class.name} to have an attribute :#{attribute_name} " +
      "that maps inputs to outputs.\nSome inputs did not match their " +
      "outputs:\n\n" +
      pretty_failed_results
  end

  define_method(:pretty_failed_results) do
    failed_results.map do |result|
      "* Expected ‹#{result[:input].inspect}› to map to " +
        "‹#{result[:expected_output].inspect}›, but it mapped to " +
        "‹#{result[:actual_output].inspect}›"
    end.join("\n")
  end

  define_method(:failed_results) do
    results.select do |result|
      result[:expected_output] != result[:actual_output]
    end
  end

  define_method(:results) do
    @results ||= values.map do |input, expected_output|
      instance = instantiate_model_via(
        way_to_write,
        model,
        { attribute_name => input },
        defaults
      )
      actual_output = read_attribute_via(way_to_read, instance, attribute_name)
      {
        input: input,
        expected_output: expected_output,
        actual_output: actual_output
      }
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
