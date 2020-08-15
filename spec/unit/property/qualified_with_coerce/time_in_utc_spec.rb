RSpec.describe HashStruct, '.property' do
  context 'qualified with coerce: :time_in_utc' do
    reading_and_writing_attributes_via do |way_to_read, way_to_write|
      it 'defines a property that accepts a UTC Time object as-is' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps(Time.utc(2020, 1, 1) => Time.utc(2020, 1, 1))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts a UTC ISO8601 time string to a UTC Time object' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps('2020-01-01T00:00:00.000Z' => Time.utc(2020, 1, 1))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts a non-UTC ISO8601 time string to a UTC Time object' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps('2020-01-01T00:00:00.000-06:00' => Time.utc(2020, 1, 1, 6))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts an ISO8601 date string to a UTC Time object' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps('2020-01-01' => Time.utc(2020, 1, 1))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts a local Time object into UTC' do
        ClimateControl.modify('TZ' => 'America/Chicago') do
          model = define_model { property :time, coerce: :time_in_utc }

          expect(model)
            .to have_attribute(:time)
            .that_maps(Time.local(2020, 1, 1) => Time.utc(2020, 1, 1, 6))
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end

      it 'defines a property that converts a Date object into a UTC Time object' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps(Date.new(2020, 1, 1) => Time.utc(2020, 1, 1))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts a DateTime object into a UTC Time object' do
        model = define_model { property :time, coerce: :time_in_utc }

        expect(model)
          .to have_attribute(:time)
          .that_maps(DateTime.new(2020, 1, 1) => Time.utc(2020, 1, 1))
          .reading_via(way_to_read)
          .writing_via(way_to_write)
      end

      it 'defines a property that converts a TimeWithZone to a UTC time' do
        Time.use_zone "Arizona" do
          model = define_model { property :time, coerce: :time_in_utc }

          expect(model)
            .to have_attribute(:time)
            .that_maps(Time.zone.local(2020, 1, 1) => Time.utc(2020, 1, 1, 7))
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end
    end

    writing_attributes_via do |way_to_write|
      it 'defines a property that raises an error when given an uncoercible kind of value' do
        model = define_model(:Order) { property :time, coerce: :time_in_utc }

        expect(model)
          .to reject_writing_attribute(:time)
          .to('whatever')
          .with(
            HashStruct::Error,
            /^\(Order\) Could not coerce "whatever" for required property :time using :time_in_utc: /
          )
          .via(way_to_write)
      end
    end

    reading_attributes_via do |way_to_read|
      context 'and with a default provided' do
        context 'when the attribute is not provided on initialization' do
          it 'sets the attribute to the default, coercing it to a UTC Time' do
            model = define_model do
              property(
                :time,
                default: '2020-01-01T00:00:00.000Z',
                coerce: :time_in_utc
              )
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :time))
              .to eq(Time.utc(2020, 1, 1))
          end
        end

        context 'when the attribute is provided on initialization' do
          it 'uses the provided value to set the attribute' do
            model = define_model do
              property(
                :time,
                default: '2020-01-01T00:00:00.000Z',
                coerce: :time_in_utc
              )
            end
            instance = model.new(time: '2020-12-25T00:00:00.000Z')

            expect(read_attribute_via(way_to_read, instance, :time))
              .to eq(Time.utc(2020, 12, 25))
          end
        end
      end
    end
  end
end
