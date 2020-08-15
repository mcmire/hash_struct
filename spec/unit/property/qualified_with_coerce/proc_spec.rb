RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: <a proc>' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that coerces given values by feeding them to the proc' do
        model = define_model(:Address) do
          property :country, coerce: -> (name) { name.downcase.to_sym }
        end

        expect(model)
          .to have_attribute(:country)
          .that_maps('US' => :us)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible value' do
        model = define_model(:Address) do
          property :country, coerce: -> (name) { name.downcase.to_sym }
        end

        expect(model)
          .to reject_writing_attribute(:country)
          .to({ foo: 'bar' })
          .with(
            HashStruct::Error,
            /^\(Address\) Could not coerce {:foo=>"bar"} for required property :country using a custom proc: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it appropriately' do
            model = define_model(:Address) do
              property :country,
                default: 'US',
                coerce: -> (name) { name.downcase.to_sym }
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :country))
              .to be(:us)
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model(:Address) do
              property :country,
                default: :us,
                coerce: -> (name) { name.downcase.to_sym }
            end
            instance = model.new(country: 'CA')

            expect(read_attribute_via(way_to_read, instance, :country))
              .to be(:ca)
          end
        end
      end
    end
  end
end
