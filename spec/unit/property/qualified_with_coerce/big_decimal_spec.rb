RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :big_decimal' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts BigDecimals as-is' do
        model = define_model { property :price, coerce: :big_decimal }

        expect(model)
          .to have_attribute(:price)
          .that_maps(BigDecimal('12.34') => BigDecimal('12.34'))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces integers to BigDecimals' do
        model = define_model { property :price, coerce: :big_decimal }

        expect(model)
          .to have_attribute(:price)
          .that_maps(12 => BigDecimal('12'))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that raises an error when given a float' do
        model = define_model(:Product) do
          property :price, coerce: :big_decimal
        end

        expect(model)
          .to reject_writing_attribute(:price)
          .to(12.34)
          .with(
            HashStruct::Error,
            "(Product) Could not coerce 12.34 for required property :price using :big_decimal: can't omit precision for a Float. (ArgumentError)"
          )
          .via(way_to_write)
      end

      it 'defines a property that coerces number-like strings to BigDecimals' do
        model = define_model { property :price, coerce: :big_decimal }

        expect(model)
          .to have_attribute(:price)
          .that_maps('12.34' => BigDecimal('12.34'))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given a non-number-like string' do
        model = define_model(:Product) do
          property :price, coerce: :big_decimal
        end

        expect(model)
          .to reject_writing_attribute(:price)
          .to('whatever')
          .with(
            HashStruct::Error,
            /^\(Product\) Could not coerce "whatever" for required property :price using :big_decimal: /
          )
          .via(way_to_write)
      end

      it 'defines a property that raises an error when given a value that is not a string or number' do
        model = define_model(:Product) do
          property :price, coerce: :big_decimal
        end

        expect(model)
          .to reject_writing_attribute(:price)
          .to(['some garbage'])
          .with(
            HashStruct::Error,
            /^\(Product\) Could not coerce \["some garbage"\] for required property :price using :big_decimal: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a BigDecimal' do
            model = define_model do
              property :price, default: '2.3', coerce: :big_decimal
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :price))
              .to eq(BigDecimal('2.3'))
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :price,
                default: BigDecimal('2.3'),
                coerce: :big_decimal
            end
            instance = model.new(price: '8.9')

            expect(read_attribute_via(way_to_read, instance, :price))
              .to eq(BigDecimal('8.9'))
          end
        end
      end
    end
  end
end
