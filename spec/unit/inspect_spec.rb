RSpec.describe HashStruct do
  ['inspect', 'to_s'].each do |method_name|
    describe "##{method_name}" do
      it 'returns a single-line representation of the HashStruct, including readonly attributes and aliases, and handling nested HashStructs' do
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
          property :location, coerce: location_model
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

        expect(store.send(method_name)).to eq(
          '#<Store employees: [#<Person first_name: "Marty", last_name: "McFly">, #<Person first_name: "Doc", last_name: "Brown">], location: #<Location lat: 30.23, lng: -59.34, type: :residential>, name: "Raleigh", promotions_by_product_id: {10=>0.304e2, 15=>0.843e2}, supported_product_ids: [1, 2, 3]>'
        )
      end
    end
  end
end
