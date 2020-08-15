RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: <another HashStruct class>' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that coerces given values into instances of the given class' do
        address_model = define_model(:Address) { property :city }
        person_model = define_model(:Person) do
          property :address, coerce: address_model
        end

        expect(person_model)
          .to have_attribute(:address)
          .that_maps(
            { city: 'Denver' } => address_model.new(city: 'Denver')
          )
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible value' do
        address_model = define_model(:Address) { property :city }
        person_model = define_model(:Person) do
          property :address, coerce: address_model
        end

        expect(person_model)
          .to reject_writing_attribute(:address)
          .to('whatever')
          .with(
            HashStruct::Error,
            /^\(Person\) Could not coerce "whatever" for required property :address using Address: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it appropriately' do
            address_model = define_model(:Address) { property :city }
            person_model = define_model(:Person) do
              property :address,
                coerce: address_model,
                default: { city: 'Denver' }
            end
            instance = person_model.new

            expect(read_attribute_via(way_to_read, instance, :address))
              .to eq(address_model.new(city: 'Denver'))
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            address_model = define_model(:Address) { property :city }
            person_model = define_model(:Person) do
              property :address,
                coerce: address_model,
                default: address_model.new(city: 'Denver')
            end
            instance = person_model.new(address: { city: 'Boulder' })

            expect(read_attribute_via(way_to_read, instance, :address))
              .to eq(address_model.new(city: 'Boulder'))
          end
        end
      end
    end
  end
end
