RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :float' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts floats as-is' do
        model = define_model { property :price, coerce: :float }

        expect(model)
          .to have_attribute(:price)
          .that_maps(12.34 => 12.34)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces integers to floats' do
        model = define_model { property :price, coerce: :float }

        expect(model)
          .to have_attribute(:price)
          .that_maps(12 => 12.0)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces BigDecimals to floats' do
        model = define_model { property :price, coerce: :float }

        expect(model)
          .to have_attribute(:price)
          .that_maps(BigDecimal('12') => 12.0)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces number-like strings to floats' do
        model = define_model { property :price, coerce: :float }

        expect(model)
          .to have_attribute(:price)
          .that_maps('12.34' => 12.34)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given a value that is not a string or number' do
        model = define_model(:Product) { property :price, coerce: :float }

        expect(model)
          .to reject_writing_attribute(:price)
          .to('whatever')
          .with(
            HashStruct::Error,
            /^\(Product\) Could not coerce "whatever" for required property :price using :float: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a float' do
            model = define_model do
              property :price, default: '2.3', coerce: :float
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :price))
              .to be(2.3)
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :price, default: 2.3, coerce: :float
            end
            instance = model.new(price: '8.9')

            expect(read_attribute_via(way_to_read, instance, :price))
              .to be(8.9)
          end
        end
      end
    end
  end
end
