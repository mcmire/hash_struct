RSpec.describe HashStruct do
  [:write_attribute, :[]=].each do |method_name|
    describe "##{method_name}" do
      context 'when the given name does not correspond to a defined property' do
        it 'raises an HashStruct::Error' do
          model = define_model(:Product)
          writing_property = -> do
            instantiate_model_via(method_name, model, some_property: 'whatever')
          end

          expect(&writing_property).to raise_error(
            HashStruct::Error,
            '(Product) Unrecognized property :some_property.'
          )
        end
      end

      if method_name == :write_attribute
        context 'given override: true when the attribute is readonly' do
          it 'does not raise an error' do
            model = define_model(:Product) do
              property :name, readonly: true
            end

            writing_attribute = lambda do
              model.new.write_attribute(:name, 'Elliot', override: true)
            end

            expect(&writing_attribute).not_to raise_error
          end
        end
      end
    end
  end
end
