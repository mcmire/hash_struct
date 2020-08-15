RSpec.describe HashStruct do
  [:read_attribute, :[]].each do |method_name|
    describe "##{method_name}" do
      context 'when the given name does not correspond to a defined property' do
        it 'raises an HashStruct::Error' do
          model = define_model(:Product)
          reading_property = -> do
            read_attribute_via(method_name, model.new, :some_property)
          end

          expect(&reading_property).to raise_error(
            HashStruct::Error,
            '(Product) Unrecognized property :some_property.'
          )
        end
      end
    end
  end
end
