RSpec.describe HashStruct, '#==' do
  context 'given a hash' do
    context 'that is user-supplied' do
      context 'when the hash lines up exactly with the attributes of this HashStruct, considering readonly attributes, aliases, and nested HashStructs' do
        it 'returns true' do
          person_model = define_model(:Person) do
            property :first_name
            property :last_name
          end
          location_model = define_model(:Location) do
            property :lat, coerce: :float
            property :lng, coerce: :float
            property(:type, readonly: true, coerce: :symbol) { :residential }
          end
          store_model = define_model(:Store) do
            property :name
            property :location, aliases: [:geo_location], coerce: location_model
            property(
              :supported_product_ids,
              coerce: Array[:integer]
            )
            property(
              :promotions_by_product_id,
              coerce: Hash[:integer => :big_decimal]
            )
            property :employees, coerce: Array[person_model]
          end
          store = store_model.new(
            name: 'Raleigh',
            location: { lat: 30.23, lng: -59.34 },
            supported_product_ids: [1, 2, 3],
            promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
            employees: [
              { first_name: 'Marty', last_name: 'McFly' },
              { first_name: 'Doc', last_name: 'Brown' }
            ]
          )

          expect(store).to eq({
            name: 'Raleigh',
            'geo_location' => location_model.new(
              lat: 30.23,
              lng: -59.34
            ),
            supported_product_ids: [1, 2, 3],
            'promotions_by_product_id' => {
              10 => BigDecimal('30.4'),
              15 => BigDecimal('84.3')
            },
            employees: [
              { first_name: 'Marty', 'last_name' => 'McFly' },
              { first_name: 'Doc', last_name: 'Brown' }
            ]
          })
        end
      end

      context "which presumably represents a HashStruct's attributes but omits one of its readonly attributes" do
        it 'returns false' do
          pending 'Not sure if this will work anymore'

          model = define_model do
            property :name, aliases: [:full_name]
            property :age
            property(:gender, readonly: true) { :male }
          end

          instance = model.new(name: 'Elliot', age: 31)

          expect(instance).not_to eq({
            name: 'Elliot',
            age: 31
          })
        end
      end

      context "which presumably represents a HashStruct's attributes but doesn't match one of its readonly attributes" do
        it 'returns false' do
          model = define_model do
            property :name, aliases: [:full_name]
            property :age
            property(:gender, readonly: true) { :male }
          end

          instance = model.new(name: 'Elliot', age: 31)

          expect(instance).not_to eq({
            name: 'Elliot',
            age: 31,
            gender: 'female'
          })
        end
      end

      context "which cannot be turned into an instance of this HashStruct" do
        it 'returns false' do
          model = define_model { property :name }

          instance = model.new(name: 'Elliot')

          expect(instance).not_to eq(age: 31)
        end
      end
    end

    context 'that comes from #to_h' do
      it 'returns true' do
        person_model = define_model(:Person) do
          property :first_name
          property :last_name
        end
        location_model = define_model(:Location) do
          property :lat, coerce: :float
          property :lng, coerce: :float
          property(:type, readonly: true, coerce: :symbol) { :residential }
        end
        store_model = define_model(:Store) do
          property :name
          property :location, aliases: [:geo_location], coerce: location_model
          property(
            :supported_product_ids,
            coerce: Array[:integer]
          )
          property(
            :promotions_by_product_id,
            coerce: Hash[:integer => :big_decimal]
          )
          property :employees, coerce: Array[person_model]
        end
        store = store_model.new(
          name: 'Raleigh',
          location: { lat: 30.23, lng: -59.34 },
          supported_product_ids: [1, 2, 3],
          promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
          employees: [
            { first_name: 'Marty', last_name: 'McFly' },
            { first_name: 'Doc', last_name: 'Brown' }
          ]
        )

        expect(store).to eq(store.to_h)
      end
    end
  end
end
