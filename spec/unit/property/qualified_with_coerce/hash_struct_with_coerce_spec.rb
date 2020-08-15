RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: <another HashStruct class that responds to #coerce>' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that coerces given values through .coerce on the given class' do
        country_class = define_model(:Country) do
          def self.coerce(value)
            name = { us: 'US', ca: 'CA' }.fetch(value)
            new(name: name)
          end

          property :name
        end
        address_model = define_model(:Address) do
          property :country, coerce: country_class
        end

        expect(address_model)
          .to have_attribute(:country)
          .with_default(:ca)
          .that_maps(:us => country_class.new(name: 'US'))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible value' do
        country_class = define_model(:Country) do
          def self.coerce(value)
            name = { us: 'US', ca: 'CA' }.fetch(value)
            new(name: name)
          end

          property :name
        end
        address_model = define_model(:Address) do
          property :country, coerce: country_class
        end

        expect(address_model)
          .to reject_writing_attribute(:country)
          .with_default(:ca)
          .to(:unknown)
          .with(
            HashStruct::Error,
            /^\(Address\) Could not coerce :unknown for required property :country using Country: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it appropriately' do
            country_class = define_model(:Country) do
              def self.coerce(value)
                name = { us: 'US', ca: 'CA' }.fetch(value)
                new(name: name)
              end

              property :name
            end
            address_model = define_model(:Address) do
              property :country, default: :us, coerce: country_class
            end
            address = address_model.new

            expect(read_attribute_via(way_to_read, address, :country))
              .to eq(country_class.new(name: 'US'))
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            country_class = define_model(:Country) do
              def self.coerce(value)
                name = { us: 'US', ca: 'CA' }.fetch(value)
                new(name: name)
              end

              property :name
            end
            address_model = define_model(:Address) do
              property :country, default: 'US', coerce: country_class
            end
            address = address_model.new(country: :ca)

            expect(read_attribute_via(way_to_read, address, :country))
              .to eq(country_class.new(name: 'CA'))
          end
        end
      end
    end
  end
end
