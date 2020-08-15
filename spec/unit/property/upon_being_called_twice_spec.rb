RSpec.describe HashStruct, '.property' do
  context 'upon being called twice' do
    context 'using the same name both times' do
      reading_and_writing_attributes_via do |way_to_read, way_to_write|
        it 'merges the given options with the options the property was defined with' do
          model = define_model do
            property :some_property, required: true, coerce: :integer
            property :some_property, required: false, coerce: :string
          end

          expect(model)
            .to have_attribute(:some_property)
            .that_maps('some value' => 'some value', nil => nil)
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end
    end

    context 'the second time using an alias of the original property' do
      reading_and_writing_attributes_via do |way_to_read, way_to_write|
        it 'merges the given options with the options the property was defined with' do
          model = define_model do
            property(
              :some_property,
              aliases: [:alias_property],
              required: true,
              coerce: :integer
            )
            property :alias_property, required: false, coerce: :string
          end

          expect(model)
            .to have_attribute(:some_property)
            .that_maps('some value' => 'some value', nil => nil)
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end
    end
  end
end
