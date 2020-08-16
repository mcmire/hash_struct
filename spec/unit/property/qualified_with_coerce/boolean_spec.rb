RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :boolean' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts true as-is' do
        model = define_model { property :notify, coerce: :boolean }

        expect(model)
          .to have_attribute(:notify)
          .that_maps(true => true)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that accepts false as-is' do
        model = define_model { property :notify, coerce: :boolean }

        expect(model)
          .to have_attribute(:notify)
          .that_maps(false => false)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that coerces truthy values to true' do
        model = define_model { property :notify, coerce: :boolean }

        expect(model)
          .to have_attribute(:notify)
          .that_maps('anything' => true, 1 => true, [1, 2, 3] => true)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      # TODO: Should this be the case? Should nil turn into false or should it
      # raise an error since the property is required?
      it 'defines a property that coerces falsey values to false' do
        model = define_model { property :notify, coerce: :boolean }

        expect(model)
          .to have_attribute(:notify)
          .that_maps(false => false, nil => false)
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a boolean' do
            model = define_model do
              property :notify, default: 'yes', coerce: :boolean
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :notify))
              .to be(true)
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property :notify, default: true, coerce: :boolean
            end
            instance = model.new(notify: false)

            expect(read_attribute_via(way_to_read, instance, :notify))
              .to be(false)
          end
        end
      end
    end
  end
end
