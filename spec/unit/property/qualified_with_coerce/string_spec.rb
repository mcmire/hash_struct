RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :string' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that ignores empty strings' do
        model = define_model { property :name, coerce: :string }

        expect(model)
          .to have_attribute(:name)
          .that_maps('' => '')
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that ignores non-empty strings' do
        model = define_model { property :name, coerce: :string }

        expect(model)
          .to have_attribute(:name)
          .that_maps('Elliot' => 'Elliot')
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces non-string values to strings' do
        model = define_model { property :name, coerce: :string }

        expect(model)
          .to have_attribute(:name)
          .that_maps(
            1234 => '1234',
            :foo => 'foo',
            [1, 2, 3] => '[1, 2, 3]',
            { foo: 'bar' } => '{:foo=>"bar"}'
          )
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a string' do
            model = define_model do
              property :name, default: 123, coerce: :string
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :name))
              .to eq('123')
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :name, default: 'Anonymous', coerce: :string
            end
            instance = model.new(name: 456)

            expect(read_attribute_via(way_to_read, instance, :name))
              .to eq('456')
          end
        end
      end
    end
  end
end
