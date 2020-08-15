RSpec.describe HashStruct, '#merge' do
  it 'returns a copy of this HashStruct, assigning each key/value pair to it' do
    model = define_model do
      property :name
      property :price
    end

    instance = model.new(name: 'Pillow', price: 10)
    new_instance = instance.merge(name: 'Sheets')

    expect(new_instance.attributes).to eq(name: 'Sheets', price: 10)
  end

  it 'does not attempt to copy readonly attributes to the new model' do
    model = define_model do
      property :name
      property :price
      property :original_price, readonly: true

      after_writing_attribute :price do |value|
        write_attribute(:original_price, value, override: true)
      end
    end

    instance = model.new(name: 'Pillow', price: 10)
    new_instance = instance.merge(name: 'Sheets')

    expect(new_instance.attributes).to eq(name: 'Sheets', price: 10)
  end
end
