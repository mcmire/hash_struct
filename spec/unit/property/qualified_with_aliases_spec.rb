RSpec.describe HashStruct, '.property' do
  context 'qualified with :aliases' do
    reading_attributes_via do |way_to_read|
      it 'enables reading and writing the property using different names' do
        model = define_model do
          property :last_name, aliases: [:family_name, :surname]
        end
        instance = model.new(last_name: 'Winkler')

        expect(read_attribute_via(way_to_read, instance, :family_name))
          .to eq('Winkler')
        expect(read_attribute_via(way_to_read, instance, :surname))
          .to eq('Winkler')
      end
    end
  end
end
