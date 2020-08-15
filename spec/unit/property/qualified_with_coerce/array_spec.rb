RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: Array[<scalar type>]' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts an array of <type> as-is' do
        model = define_model do
          property :possible_states, coerce: Array[:symbol]
        end

        expect(model)
          .to have_attribute(:possible_states)
          .that_maps([:opened, :closed] => [:opened, :closed])
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces given values to an array of <type>' do
        model = define_model do
          property :possible_states, coerce: Array[:symbol]
        end

        expect(model)
          .to have_attribute(:possible_states)
          .that_maps(['opened', 'closed'] => [:opened, :closed])
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible kind of value' do
        model = define_model(:Order) do
          property :possible_states, coerce: Array[:symbol]
        end

        expect(model)
          .to reject_writing_attribute(:possible_states)
          .to({ foo: 'bar' })
          .with(
            HashStruct::Error,
            /^\(Order\) Could not coerce {:foo=>"bar"} for required property :possible_states using Array\[:symbol\]: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to an array of <type>' do
            model = define_model do
              property :possible_states,
                default: ['inside'],
                coerce: Array[:symbol]
            end
            instance = model.new

            attribute_value = read_attribute_via(
              way_to_read,
              instance,
              :possible_states
            )
            expect(attribute_value).to eq([:inside])
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :possible_states,
                default: [:inside],
                coerce: Array[:symbol]
            end
            instance = model.new(possible_states: [:outside])

            attribute_value = read_attribute_via(
              way_to_read,
              instance,
              :possible_states
            )
            expect(attribute_value).to eq([:outside])
          end
        end
      end
    end
  end
end
