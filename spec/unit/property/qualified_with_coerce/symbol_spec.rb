RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :symbol' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts symbols as-is' do
        model = define_model { property :state, coerce: :symbol }

        expect(model)
          .to have_attribute(:state)
          .that_maps(:opened => :opened)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces strings to symbols' do
        model = define_model { property :state, coerce: :symbol }

        expect(model)
          .to have_attribute(:state)
          .that_maps('opened' => :opened)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible kind of value' do
        model = define_model(:Order) { property :state, coerce: :symbol }

        expect(model)
          .to reject_writing_attribute(:state)
          .to({ foo: 'bar' })
          .with(
            HashStruct::Error,
            /^\(Order\) Could not coerce {:foo=>"bar"} for required property :state using :symbol: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a symbol' do
            model = define_model do
              property :state, default: 'processed', coerce: :symbol
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :state))
              .to be(:processed)
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :state, default: :processed, coerce: :symbol
            end
            instance = model.new(state: 'closed')

            expect(read_attribute_via(way_to_read, instance, :state))
              .to be(:closed)
          end
        end
      end
    end
  end
end
