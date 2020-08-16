RSpec.describe HashStruct, '.property' do
  context 'specified as string' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'works just as though the property had been specified as a symbol' do
        model = define_model { property 'value' }

        expect(model)
          .to have_attribute(:value)
          .that_maps('some value' => 'some value')
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end
  end
end
