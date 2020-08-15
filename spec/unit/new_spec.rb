RSpec.describe HashStruct, '.new' do
  context 'given a HashStruct' do
    it 'returns a new HashStruct with the same attributes of the given one' do
      model = define_model do
        property :name
        property :price
      end

      product1 = model.new(name: 'Pillow', price: 10)
      product2 = model.new(product1)

      expect(product2.written_attributes).to eq(product1.written_attributes)
    end
  end

  context 'given a hash' do
    context "when the name of a given attribute does not correspond to a defined property" do
      it 'raises an HashStruct::Error' do
        model = define_model(:Product)
        initializing_model = -> { model.new(some_property: 'whatever') }

        expect(&initializing_model).to raise_error(
          HashStruct::Error,
          '(Product) Unrecognized property :some_property.'
        )
      end
    end
  end
end
