RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: <a class that does not respond to #coerce>' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that coerces given values into instances of the given class' do
        country_class =
          define_class(:Country, superclass: Struct.new(:name)) do
            def initialize(name)
              super(name.downcase.to_sym)
            end
          end
        address_model = define_model(:Address) do
          property :country, coerce: country_class
        end

        expect(address_model)
          .to have_attribute(:country)
          .that_maps('US' => country_class.new(:us))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible value' do
        country_class =
          define_class(:Country, superclass: Struct.new(:name)) do
            def initialize(name)
              super(name.downcase.to_sym)
            end
          end
        address_model = define_model(:Address) do
          property :country, coerce: country_class
        end

        expect(address_model)
          .to reject_writing_attribute(:country)
          .to({ foo: 'bar' })
          .with(
            HashStruct::Error,
            /^\(Address\) Could not coerce {:foo=>"bar"} for required property :country using Country: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it appropriately' do
            country_class =
              define_class(:Country, superclass: Struct.new(:name)) do
                def initialize(name)
                  super(name.downcase.to_sym)
                end
              end
            address_model = define_model(:Address) do
              property :country, default: 'US', coerce: country_class
            end
            address = address_model.new

            expect(read_attribute_via(way_to_read, address, :country))
              .to eq(country_class.new(:us))
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            country_class =
              define_class(:Country, superclass: Struct.new(:name)) do
                def initialize(name)
                  super(name.downcase.to_sym)
                end
              end
            address_model = define_model(:Address) do
              property :country,
                default: country_class.new(:us),
                coerce: country_class
            end
            address = address_model.new(country: 'CA')

            expect(read_attribute_via(way_to_read, address, :country))
              .to eq(country_class.new(:ca))
          end
        end
      end
    end
  end
end
