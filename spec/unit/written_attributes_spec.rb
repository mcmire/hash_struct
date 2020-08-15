RSpec.describe HashStruct, "#written_attributes" do
  it 'returns a hash of name => value from the properties of this HashStruct that are not read-only, excluding aliases' do
    model = define_model do
      property :name, aliases: [:full_name]
      property :age
      property(:gender, readonly: true) { :male }
    end

    instance = model.new(name: 'Elliot', age: 31)

    expect(instance.written_attributes).to eq(name: 'Elliot', age: 31)
  end
end
