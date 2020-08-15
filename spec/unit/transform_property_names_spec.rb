RSpec.describe HashStruct, '.transform_property_names' do
  it 'sets a callback that can be used to normalize incoming data' do
    model = define_model do
      property :first_name
      property :last_name

      transform_property_names do |name|
        name.to_s.downcase.gsub(/ /, '_').to_sym
      end
    end

    instance = model.new('FIRST NAME' => 'Elliot', 'LAST NAME' => 'Winkler')

    expect(instance.written_attributes).to eq({
      first_name: 'Elliot',
      last_name: 'Winkler'
    })
  end
end
