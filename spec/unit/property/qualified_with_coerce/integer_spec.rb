RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :integer' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts integers as-is' do
        model = define_model { property :age, coerce: :integer }

        expect(model)
          .to have_attribute(:age)
          .that_maps(30 => 30)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces floats to integers (by truncating)' do
        model = define_model { property :age, coerce: :integer }

        expect(model)
          .to have_attribute(:age)
          .that_maps(30.3 => 30)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces BigDecimals to integers (by truncating)' do
        model = define_model { property :age, coerce: :integer }

        expect(model)
          .to have_attribute(:age)
          .that_maps(BigDecimal('30.3') => 30)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces number-like strings to integers' do
        model = define_model { property :age, coerce: :integer }

        expect(model)
          .to have_attribute(:age)
          .that_maps('30' => 30)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given a value that is not a string or number' do
        model = define_model(:Product) { property :age, coerce: :integer }

        expect(model)
          .to reject_writing_attribute(:age)
          .to('whatever')
          .with(
            HashStruct::Error,
            /^\(Product\) Could not coerce "whatever" for required property :age using :integer: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to an integer' do
            model = define_model do
              property :age, default: '20', coerce: :integer
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :age))
              .to be(20)
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :age, default: 20, coerce: :integer
            end
            instance = model.new(age: '59')

            expect(read_attribute_via(way_to_read, instance, :age))
              .to be(59)
          end
        end
      end
    end
  end
end
