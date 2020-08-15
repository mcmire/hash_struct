RSpec.describe HashStruct, '#to_h' do
  it 'returns the attributes of the HashStruct, including aliases, and the attributes of nested HashStructs' do
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

    expect(store.to_h).to eq({
      name: 'Raleigh',
      location: { lat: 30.23, lng: -59.34, type: :residential },
      supported_product_ids: [1, 2, 3],
      promotions_by_product_id: {
        10 => BigDecimal('30.4'),
        15 => BigDecimal('84.3')
      },
      employees: [
        { first_name: 'Marty', last_name: 'McFly' },
        { first_name: 'Doc', last_name: 'Brown' }
      ]
    })
  end
end
