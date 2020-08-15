RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :non_blank_string' do
    writing_attributes_via do |way_to_write|
      context 'when also qualified with required: true' do
        it 'defines a property that raises an error when given an empty string' do
          model = define_model(:Person) do
            property :name, coerce: :non_blank_string, required: true
          end

          expect(model)
            .to reject_writing_attribute(:name)
            .to('')
            .with(
              HashStruct::Error,
              '(Person) Required property :name was missing or set ' +
              'to nil.'
            )
            .via(way_to_write)
        end
      end
    end

    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      context 'when also qualified with required: false' do
        it 'defines a property that coerces empty strings to nil' do
          model = define_model do
            property :name, coerce: :non_blank_string, required: false
          end

          expect(model)
            .to have_attribute(:name)
            .that_maps('' => nil)
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end
    end

    writing_attributes_via do |way_to_write|
      context 'when not qualified with :required' do
        it 'defines a property that raises an error when given an empty string' do
          model = define_model(:Person) do
            property :name, coerce: :non_blank_string
          end

          expect(model)
            .to reject_writing_attribute(:name)
            .to('')
            .with(
              HashStruct::Error,
              '(Person) Required property :name was missing or set ' +
              'to nil.'
            )
            .via(way_to_write)
        end
      end
    end

    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      context 'regardless of whether :required is true or false' do
        it 'defines a property that ignores non-empty strings' do
          model = define_model do
            property :name, coerce: :non_blank_string
          end

          expect(model)
            .to have_attribute(:name)
            .that_maps('Elliot' => 'Elliot')
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end

        it 'defines a property that coerces non-string values to strings' do
          model = define_model do
            property :name, coerce: :non_blank_string
          end

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
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a string' do
            model = define_model do
              property :name, default: 123, coerce: :non_blank_string
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :name))
              .to eq('123')
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :name, default: 'Anonymous', coerce: :non_blank_string
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
