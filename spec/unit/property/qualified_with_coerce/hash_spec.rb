RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: Hash[<scalar type> => <scalar type>]' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts an hash of <type> => <type> as-is' do
        model = define_model do
          property(
            :product_promotions,
            coerce: Hash[:integer => :big_decimal]
          )
        end

        expect(model)
          .to have_attribute(:product_promotions)
          .that_maps(
            { 34 => BigDecimal('93.23') } => { 34 => BigDecimal('93.23') }
          )
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces given values to an array of <type>' do
        model = define_model do
          property(
            :product_promotions,
            coerce: Hash[:integer => :big_decimal]
          )
        end

        expect(model)
          .to have_attribute(:product_promotions)
          .that_maps({ '34' => '93.23' } => { 34 => BigDecimal('93.23') })
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible kind of value' do
        model = define_model(:Promotion) do
          property(
            :product_promotions,
            coerce: Hash[:integer => :big_decimal]
          )
        end

        expect(model)
          .to reject_writing_attribute(:product_promotions)
          .to('clearly not a hash')
          .with(
            HashStruct::Error,
            /^\(Promotion\) Could not coerce "clearly not a hash" for required property :product_promotions using Hash\[:integer => :big_decimal\]: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to an array of <type>' do
            model = define_model(:Promotion) do
              property(
                :product_promotions,
                default: { '34' => '93.23' },
                coerce: Hash[:integer => :big_decimal]
              )
            end
            instance = model.new

            attribute_value = read_attribute_via(
              way_to_read,
              instance,
              :product_promotions
            )
            expect(attribute_value).to eq({ 34 => BigDecimal('93.23') })
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model(:Promotion) do
              property(
                :product_promotions,
                default: { 34 => BigDecimal('93.23') },
                coerce: Hash[:integer => :big_decimal]
              )
            end
            instance = model.new(
              product_promotions: { 12 => BigDecimal('0.34') }
            )

            attribute_value = read_attribute_via(
              way_to_read,
              instance,
              :product_promotions
            )
            expect(attribute_value).to eq({ 12 => BigDecimal('0.34') })
          end
        end
      end
    end
  end
end
