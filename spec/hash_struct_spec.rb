RSpec.describe HashStruct do
  extend RSpec::Matchers::DSL

  singleton_class.class_eval do
    ways_to_read_attributes = [:method, :read_attribute, :[]].freeze
    ways_to_write_attributes = [:initializer, :write_attribute, :[]=].freeze
    ways_to_read_and_write_attributes = (
      ways_to_read_attributes.flat_map do |way_to_read|
        ways_to_write_attributes.map do |way_to_write|
          [way_to_read, way_to_write]
        end
      end
    ).freeze

    define_method(:reading_attributes_via) do |&block|
      ways_to_read_attributes.each do |way_to_read|
        context "reading attributes via #{way_to_read}" do
          instance_exec(way_to_read, &block)
        end
      end
    end

    define_method(:writing_attributes_via) do |&block|
      ways_to_write_attributes.each do |way_to_write|
        context "writing attributes via #{way_to_write}" do
          instance_exec(way_to_write, &block)
        end
      end
    end

    define_method(:reading_and_writing_attributes_via) do |&block|
      ways_to_read_and_write_attributes.each do |way_to_read, way_to_write|
        context "reading attributes via #{way_to_read} and writing attributes via #{way_to_write}" do
          instance_exec(way_to_read, way_to_write, &block)
        end
      end
    end
  end

  describe '.property' do
    context 'qualified with nothing' do
      it 'defines a property that raises an error when it is not set during instantiation' do
        model = define_model(:Address) { property :city }
        assigning_attribute = -> { model.new }

        expect(&assigning_attribute).to raise_error(
          HashStruct::Error,
          '(Address) Required property :city was missing or set to nil.'
        )
      end

      writing_attributes_via do |way_to_write|
        it 'defines a property that raises an error when set to nil' do
          model = define_model(:Address) { property :city }

          expect(model)
            .to reject_writing_attribute(:city)
            .to(nil)
            .with(
              HashStruct::Error,
              '(Address) Required property :city was missing or set to nil.'
            )
            .via(way_to_write)
        end
      end

      reading_and_writing_attributes_via do |way_to_read, way_to_write|
        it 'defines a property that takes any kind of value, without coercing it' do
          model = define_model { property :value }

          expect(model)
            .to have_attribute(:value)
            .that_maps(
              'Denver, CO' => 'Denver, CO',
              1 => 1,
              :foo => :foo,
              [1, 2, 3] => [1, 2, 3],
              { foo: 'bar' } => { foo: 'bar' }
            )
            .reading_via(way_to_read)
            .writing_via(way_to_write)
        end
      end
    end

    context 'qualified with coerce:' do
      context ':big_decimal' do
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

      context ':boolean' do
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

      context ':float' do
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

      context ':integer' do
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

      context ':non_blank_string' do
        writing_attributes_via do |way_to_write|
          context 'when also qualified with required: true' do
            it 'defines a property that raises an error when given an empty string' do
              model = define_model(:Person) do
                property :name, coerce: :non_blank_string, required: true
              end

              expect(model)
                .to reject_writing_attribute(:name)
                .to('')
                .with(
                  HashStruct::Error,
                  '(Person) Required property :name was missing or set ' +
                  'to nil.'
                )
                .via(way_to_write)
            end
          end
        end

        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          context 'when also qualified with required: false' do
            it 'defines a property that coerces empty strings to nil' do
              model = define_model do
                property :name, coerce: :non_blank_string, required: false
              end

              expect(model)
                .to have_attribute(:name)
                .that_maps('' => nil)
                .reading_via(way_to_read)
                .writing_via(way_to_write)
            end
          end
        end

        writing_attributes_via do |way_to_write|
          context 'when not qualified with :required' do
            it 'defines a property that raises an error when given an empty string' do
              model = define_model(:Person) do
                property :name, coerce: :non_blank_string
              end

              expect(model)
                .to reject_writing_attribute(:name)
                .to('')
                .with(
                  HashStruct::Error,
                  '(Person) Required property :name was missing or set ' +
                  'to nil.'
                )
                .via(way_to_write)
            end
          end
        end

        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          context 'regardless of whether :required is true or false' do
            it 'defines a property that ignores non-empty strings' do
              model = define_model do
                property :name, coerce: :non_blank_string
              end

              expect(model)
                .to have_attribute(:name)
                .that_maps('Elliot' => 'Elliot')
                .reading_via(way_to_read)
                .writing_via(way_to_write)
            end

            it 'defines a property that coerces non-string values to strings' do
              model = define_model do
                property :name, coerce: :non_blank_string
              end

              expect(model)
                .to have_attribute(:name)
                .that_maps(
                  1234 => '1234',
                  :foo => 'foo',
                  [1, 2, 3] => '[1, 2, 3]',
                  { foo: 'bar' } => '{:foo=>"bar"}'
                )
                .reading_via(way_to_read)
                .writing_via(way_to_write)
            end
          end
        end

        reading_attributes_via do |way_to_read|
          context 'and with a default provided' do
            context 'when the attribute is not provided on initialization' do
              it 'sets the attribute to the default, coercing it to a string' do
                model = define_model do
                  property :name, default: 123, coerce: :non_blank_string
                end
                instance = model.new

                expect(read_attribute_via(way_to_read, instance, :name))
                  .to eq('123')
              end
            end

            context 'when the attribute is provided on initialization' do
              it 'uses the provided value to set the attribute' do
                model = define_model do
                  property :name, default: 'Anonymous', coerce: :non_blank_string
                end
                instance = model.new(name: 456)

                expect(read_attribute_via(way_to_read, instance, :name))
                  .to eq('456')
              end
            end
          end
        end
      end

      context ':string' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'defines a property that ignores empty strings' do
            model = define_model { property :name, coerce: :string }

            expect(model)
              .to have_attribute(:name)
              .that_maps('' => '')
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end

          it 'defines a property that ignores non-empty strings' do
            model = define_model { property :name, coerce: :string }

            expect(model)
              .to have_attribute(:name)
              .that_maps('Elliot' => 'Elliot')
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end

          it 'defines a property that coerces non-string values to strings' do
            model = define_model { property :name, coerce: :string }

            expect(model)
              .to have_attribute(:name)
              .that_maps(
                1234 => '1234',
                :foo => 'foo',
                [1, 2, 3] => '[1, 2, 3]',
                { foo: 'bar' } => '{:foo=>"bar"}'
              )
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end

        reading_attributes_via do |way_to_read|
          context 'and with a default provided' do
            context 'when the attribute is not provided on initialization' do
              it 'sets the attribute to the default, coercing it to a string' do
                model = define_model do
                  property :name, default: 123, coerce: :string
                end
                instance = model.new

                expect(read_attribute_via(way_to_read, instance, :name))
                  .to eq('123')
              end
            end

            context 'when the attribute is provided on initialization' do
              it 'uses the provided value to set the attribute' do
                model = define_model do
                  property :name, default: 'Anonymous', coerce: :string
                end
                instance = model.new(name: 456)

                expect(read_attribute_via(way_to_read, instance, :name))
                  .to eq('456')
              end
            end
          end
        end
      end

      context ':symbol' do
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

      context ':time_in_utc' do
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

      context 'Array[<scalar type>]' do
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

      context 'Hash[<scalar type> => <scalar type>]' do
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

      context '<a class that responds to #coerce>' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'defines a property that coerces given values through .coerce on the given class' do
            country_class = define_class(:Country) do
              def self.coerce(country_name)
                { us: 'US', ca: 'CA' }.fetch(country_name)
              end
            end
            address_model = define_model(:Address) do
              property :country, coerce: country_class
            end

            expect(address_model)
              .to have_attribute(:country)
              .with_default(:ca)
              .that_maps(:us => 'US')
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end

        writing_attributes_via do |way_to_write|
          it 'defines a property that raises an error when given an uncoercible value' do
            country_class = define_class(:Country) do
              def self.coerce(country_name)
                { us: 'US', ca: 'CA' }.fetch(country_name)
              end
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
                country_class = define_class(:Country) do
                  def self.coerce(country_name)
                    { us: 'US', ca: 'CA' }.fetch(country_name)
                  end
                end
                address_model = define_model(:Address) do
                  property :country, default: :us, coerce: country_class
                end
                address = address_model.new

                expect(read_attribute_via(way_to_read, address, :country))
                  .to eq('US')
              end
            end

            context 'when the attribute is provided on initialization' do
              it 'uses the provided value to set the attribute' do
                country_class = define_class(:Country) do
                  def self.coerce(country_name)
                    { us: 'US', ca: 'CA' }.fetch(country_name)
                  end
                end
                address_model = define_model(:Address) do
                  property :country, default: 'US', coerce: country_class
                end
                address = address_model.new(country: :ca)

                expect(read_attribute_via(way_to_read, address, :country))
                  .to eq('CA')
              end
            end
          end
        end
      end

      context '<another HashStruct class that responds to #coerce>' do
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

      context '<another HashStruct class>' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'defines a property that coerces given values into instances of the given class' do
            address_model = define_model(:Address) { property :city }
            person_model = define_model(:Person) do
              property :address, coerce: address_model
            end

            expect(person_model)
              .to have_attribute(:address)
              .that_maps(
                { city: 'Denver' } => address_model.new(city: 'Denver')
              )
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end

        writing_attributes_via do |way_to_write|
          it 'defines a property that raises an error when given an uncoercible value' do
            address_model = define_model(:Address) { property :city }
            person_model = define_model(:Person) do
              property :address, coerce: address_model
            end

            expect(person_model)
              .to reject_writing_attribute(:address)
              .to('whatever')
              .with(
                HashStruct::Error,
                /^\(Person\) Could not coerce "whatever" for required property :address using Address: /
              )
              .via(way_to_write)
          end
        end

        reading_attributes_via do |way_to_read|
          context 'and with a default provided' do
            context 'when the attribute is not provided on initialization' do
              it 'sets the attribute to the default, coercing it appropriately' do
                address_model = define_model(:Address) { property :city }
                person_model = define_model(:Person) do
                  property :address,
                    coerce: address_model,
                    default: { city: 'Denver' }
                end
                instance = person_model.new

                expect(read_attribute_via(way_to_read, instance, :address))
                  .to eq(address_model.new(city: 'Denver'))
              end
            end

            context 'when the attribute is provided on initialization' do
              it 'uses the provided value to set the attribute' do
                address_model = define_model(:Address) { property :city }
                person_model = define_model(:Person) do
                  property :address,
                    coerce: address_model,
                    default: address_model.new(city: 'Denver')
                end
                instance = person_model.new(address: { city: 'Boulder' })

                expect(read_attribute_via(way_to_read, instance, :address))
                  .to eq(address_model.new(city: 'Boulder'))
              end
            end
          end
        end
      end

      context '<a class that does not respond to #coerce>' do
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

      context '<a proc>' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'defines a property that coerces given values by feeding them to the proc' do
            model = define_model(:Address) do
              property :country, coerce: -> (name) { name.downcase.to_sym }
            end

            expect(model)
              .to have_attribute(:country)
              .that_maps('US' => :us)
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end

        writing_attributes_via do |way_to_write|
          it 'defines a property that raises an error when given an uncoercible value' do
            model = define_model(:Address) do
              property :country, coerce: -> (name) { name.downcase.to_sym }
            end

            expect(model)
              .to reject_writing_attribute(:country)
              .to({ foo: 'bar' })
              .with(
                HashStruct::Error,
                /^\(Address\) Could not coerce {:foo=>"bar"} for required property :country using a custom proc: /
              )
              .via(way_to_write)
          end
        end

        reading_attributes_via do |way_to_read|
          context 'and with a default provided' do
            context 'when the attribute is not provided on initialization' do
              it 'sets the attribute to the default, coercing it appropriately' do
                model = define_model(:Address) do
                  property :country,
                    default: 'US',
                    coerce: -> (name) { name.downcase.to_sym }
                end
                instance = model.new

                expect(read_attribute_via(way_to_read, instance, :country))
                  .to be(:us)
              end
            end

            context 'when the attribute is provided on initialization' do
              it 'uses the provided value to set the attribute' do
                model = define_model(:Address) do
                  property :country,
                    default: :us,
                    coerce: -> (name) { name.downcase.to_sym }
                end
                instance = model.new(country: 'CA')

                expect(read_attribute_via(way_to_read, instance, :country))
                  .to be(:ca)
              end
            end
          end
        end
      end
    end

    context 'qualified with required: false' do
      it 'does not raise an error on instantiation when the attribute is not set' do
        model = define_model { property :name, required: false }
        instantiating_model = -> { model.new }

        expect(&instantiating_model).not_to raise_error
      end
    end

    context 'qualified with :aliases' do
      reading_attributes_via do |way_to_read|
        it 'enables reading and writing the property using different names' do
          model = define_model do
            property :last_name, aliases: [:family_name, :surname]
          end
          instance = model.new(last_name: 'Winkler')

          expect(read_attribute_via(way_to_read, instance, :family_name))
            .to eq('Winkler')
          expect(read_attribute_via(way_to_read, instance, :surname))
            .to eq('Winkler')
        end
      end
    end

    context 'qualified with :readonly' do
      context 'and a block' do
        reading_attributes_via do |way_to_read|
          it 'defines a property that always returns the value the block returns' do
            model = define_model do
              property(:name, readonly: true) { 'Elliot' }
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :name))
              .to eq('Elliot')
          end
        end

        writing_attributes_via do |way_to_write|
          it 'defines a property that raises an error when written' do
            model = define_model(:Product) do
              property(:name, readonly: true) { 'Elliot' }
            end

            expect(model)
              .to reject_writing_attribute(:name)
              .to('any value')
              .with(
                HashStruct::Error,
                "(Product) Couldn't write readonly attribute :name."
              )
              .via(way_to_write)
          end
        end
      end

      context 'but no block' do
        reading_attributes_via do |way_to_read|
          it 'defines a property that returns nil initially' do
            model = define_model do
              property(:name, readonly: true)
            end
            instance = model.new

            expect(read_attribute_via(way_to_read, instance, :name))
              .to be(nil)
          end

          it 'defines a property that returns its value when written manually' do
            model = define_model do
              property(:name, readonly: true)
            end
            instance = model.new
            instance.write_attribute(:name, 'Elliot', override: true)

            expect(read_attribute_via(way_to_read, instance, :name))
              .to eq('Elliot')
          end
        end

        writing_attributes_via do |way_to_write|
          it 'defines a property that raises an error when written' do
            model = define_model(:Product) do
              property(:name, readonly: true) { 'Elliot' }
            end

            expect(model)
              .to reject_writing_attribute(:name)
              .to('any value')
              .with(
                HashStruct::Error,
                "(Product) Couldn't write readonly attribute :name."
              )
              .via(way_to_write)
          end
        end
      end
    end

    context 'upon being called twice' do
      context 'using the same name both times' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'merges the given options with the options the property was defined with' do
            model = define_model do
              property :some_property, required: true, coerce: :integer
              property :some_property, required: false, coerce: :string
            end

            expect(model)
              .to have_attribute(:some_property)
              .that_maps('some value' => 'some value', nil => nil)
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end
      end

      context 'the second time using an alias of the original property' do
        reading_and_writing_attributes_via do |way_to_read, way_to_write|
          it 'merges the given options with the options the property was defined with' do
            model = define_model do
              property(
                :some_property,
                aliases: [:alias_property],
                required: true,
                coerce: :integer
              )
              property :alias_property, required: false, coerce: :string
            end

            expect(model)
              .to have_attribute(:some_property)
              .that_maps('some value' => 'some value', nil => nil)
              .reading_via(way_to_read)
              .writing_via(way_to_write)
          end
        end
      end
    end
  end

  describe '.transform_property_names' do
    it 'sets a callback that can be used to normalize incoming data' do
      model = define_model do
        property :first_name
        property :last_name

        transform_property_names do |name|
          name.to_s.downcase.gsub(/ /, '_').to_sym
        end
      end

      instance = model.new('FIRST NAME' => 'Elliot', 'LAST NAME' => 'Winkler')

      expect(instance.written_attributes).to eq({
        first_name: 'Elliot',
        last_name: 'Winkler'
      })
    end
  end

  describe '.after_writing_attribute' do
    it 'sets a callback that is called after the attribute is written' do
      fake_object = spy(:fake_object, fake_method1: nil, fake_method2: nil)
      model = define_model do
        property :name, required: false
        after_writing_attribute :name do |value|
          fake_object.fake_method1(value)
        end
        after_writing_attribute :name do |value|
          fake_object.fake_method2(value)
        end
      end

      model.new.name = 'Elliot'

      expect(fake_object).to have_received(:fake_method1).with('Elliot')
      expect(fake_object).to have_received(:fake_method2).with('Elliot')
    end
  end

  describe '.discard_all_unrecognized_attributes=' do
    context 'if set to true' do
      it "filters out keys in the incoming hash that aren't defined properties" do
        model = define_model do
          property :first_name
          property :last_name

          self.discard_all_unrecognized_attributes = true
        end

        instance = model.new(
          first_name: 'Elliot',
          last_name: 'Winkler',
          age: 32
        )

        expect(instance.written_attributes).to eq({
          first_name: 'Elliot',
          last_name: 'Winkler'
        })
      end
    end
  end

  describe 'initializer' do
    context 'given a HashStruct' do
      it 'returns a new HashStruct with the same attributes of the given one' do
        model = define_model do
          property :name
          property :price
        end

        product1 = model.new(name: 'Pillow', price: 10)
        product2 = model.new(product1)

        expect(product2.written_attributes).to eq(product1.written_attributes)
      end
    end

    context 'given a hash' do
      context "when the name of a given attribute does not correspond to a defined property" do
        it 'raises an HashStruct::Error' do
          model = define_model(:Product)
          initializing_model = -> { model.new(some_property: 'whatever') }

          expect(&initializing_model).to raise_error(
            HashStruct::Error,
            '(Product) Unrecognized property :some_property.'
          )
        end
      end
    end
  end

  describe "#written_attributes" do
    it 'returns a hash of name => value from the properties of this HashStruct that are not read-only, excluding aliases' do
      model = define_model do
        property :name, aliases: [:full_name]
        property :age
        property(:gender, readonly: true) { :male }
      end

      instance = model.new(name: 'Elliot', age: 31)

      expect(instance.written_attributes).to eq(name: 'Elliot', age: 31)
    end
  end

  [:read_attribute, :[]].each do |method_name|
    describe "##{method_name}" do
      context 'when the given name does not correspond to a defined property' do
        it 'raises an HashStruct::Error' do
          model = define_model(:Product)
          reading_property = -> do
            read_attribute_via(method_name, model.new, :some_property)
          end

          expect(&reading_property).to raise_error(
            HashStruct::Error,
            '(Product) Unrecognized property :some_property.'
          )
        end
      end
    end
  end

  [:write_attribute, :[]=].each do |method_name|
    describe "##{method_name}" do
      context 'when the given name does not correspond to a defined property' do
        it 'raises an HashStruct::Error' do
          model = define_model(:Product)
          writing_property = -> do
            instantiate_model_via(method_name, model, some_property: 'whatever')
          end

          expect(&writing_property).to raise_error(
            HashStruct::Error,
            '(Product) Unrecognized property :some_property.'
          )
        end
      end

      if method_name == :write_attribute
        context 'given override: true when the attribute is readonly' do
          it 'does not raise an error' do
            model = define_model(:Product) do
              property :name, readonly: true
            end

            writing_attribute = lambda do
              model.new.write_attribute(:name, 'Elliot', override: true)
            end

            expect(&writing_attribute).not_to raise_error
          end
        end
      end
    end
  end

  describe '#merge' do
    it 'returns a copy of this HashStruct, assigning each key/value pair to it' do
      model = define_model do
        property :name
        property :price
      end

      instance = model.new(name: 'Pillow', price: 10)
      new_instance = instance.merge(name: 'Sheets')

      expect(new_instance.attributes).to eq(name: 'Sheets', price: 10)
    end

    it 'does not attempt to copy readonly attributes to the new model' do
      model = define_model do
        property :name
        property :price
        property :original_price, readonly: true

        after_writing_attribute :price do |value|
          write_attribute(:original_price, value, override: true)
        end
      end

      instance = model.new(name: 'Pillow', price: 10)
      new_instance = instance.merge(name: 'Sheets')

      expect(new_instance.attributes).to eq(name: 'Sheets', price: 10)
    end
  end

  ['inspect', 'to_s'].each do |method_name|
    describe "##{method_name}" do
      it 'returns a single-line representation of the HashStruct, including readonly attributes and aliases, and handling nested HashStructs' do
        person_model = define_model(:Person) do
          property :first_name
          property :last_name
        end
        location_model = define_model(:Location) do
          property :lat, coerce: :float
          property :lng, coerce: :float
          property(:type, readonly: true, coerce: :symbol) { :residential }
        end
        store_model = define_model(:Store) do
          property :name
          property :location, coerce: location_model
          property(
            :supported_product_ids,
            coerce: Array[:integer]
          )
          property(
            :promotions_by_product_id,
            coerce: Hash[:integer => :big_decimal]
          )
          property :employees, coerce: Array[person_model]
        end
        store = store_model.new(
          name: 'Raleigh',
          location: { lat: 30.23, lng: -59.34 },
          supported_product_ids: [1, 2, 3],
          promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
          employees: [
            { first_name: 'Marty', last_name: 'McFly' },
            { first_name: 'Doc', last_name: 'Brown' }
          ]
        )

        expect(store.send(method_name)).to eq(
          '#<Store employees: [#<Person first_name: "Marty", last_name: "McFly">, #<Person first_name: "Doc", last_name: "Brown">], location: #<Location lat: 30.23, lng: -59.34, type: :residential>, name: "Raleigh", promotions_by_product_id: {10=>0.304e2, 15=>0.843e2}, supported_product_ids: [1, 2, 3]>'
        )
      end
    end
  end

  describe '#serialize' do
    it 'returns the attributes of the HashStruct, including aliases, converting keys and values to JSON-compatible types and nested HashStructs to hashes' do
      person_model = define_model(:Person) do
        property :first_name
        property :last_name
      end
      location_model = define_model(:Location) do
        property :lat, coerce: :float
        property :lng, coerce: :float
        property(:type, readonly: true, coerce: :symbol) { :residential }
      end
      store_model = define_model(:Store) do
        property :name
        property :location, coerce: location_model
        property(
          :supported_product_ids,
          coerce: Array[:integer]
        )
        property(
          :promotions_by_product_id,
          coerce: Hash[:integer => :big_decimal]
        )
        property :employees, coerce: Array[person_model]
        property :service_area, required: false
      end
      store = store_model.new(
        name: 'Raleigh',
        location: { lat: 30.23, lng: -59.34 },
        supported_product_ids: [1, 2, 3],
        promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
        employees: [
          { first_name: 'Marty', last_name: 'McFly' },
          { first_name: 'Doc', last_name: 'Brown' }
        ]
      )

      expect(store.serialize).to eq({
        'name' => 'Raleigh',
        'location' => {
          'lat' => 30.23,
          'lng' => -59.34,
          'type' => 'residential'
        },
        'supported_product_ids' => [1, 2, 3],
        'promotions_by_product_id' => {
          10 => '30.4',
          15 => '84.3'
        },
        'employees' => [
          { 'first_name' => 'Marty', 'last_name' => 'McFly' },
          { 'first_name' => 'Doc', 'last_name' => 'Brown' }
        ],
        'service_area' => nil
      })
    end
  end

  describe '#to_h' do
    it 'returns the attributes of the HashStruct, including aliases, and the attributes of nested HashStructs' do
      person_model = define_model(:Person) do
        property :first_name
        property :last_name
      end
      location_model = define_model(:Location) do
        property :lat, coerce: :float
        property :lng, coerce: :float
        property(:type, readonly: true, coerce: :symbol) { :residential }
      end
      store_model = define_model(:Store) do
        property :name
        property :location, coerce: location_model
        property(
          :supported_product_ids,
          coerce: Array[:integer]
        )
        property(
          :promotions_by_product_id,
          coerce: Hash[:integer => :big_decimal]
        )
        property :employees, coerce: Array[person_model]
      end
      store = store_model.new(
        name: 'Raleigh',
        location: { lat: 30.23, lng: -59.34 },
        supported_product_ids: [1, 2, 3],
        promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
        employees: [
          { first_name: 'Marty', last_name: 'McFly' },
          { first_name: 'Doc', last_name: 'Brown' }
        ]
      )

      expect(store.to_h).to eq({
        name: 'Raleigh',
        location: { lat: 30.23, lng: -59.34, type: :residential },
        supported_product_ids: [1, 2, 3],
        promotions_by_product_id: {
          10 => BigDecimal('30.4'),
          15 => BigDecimal('84.3')
        },
        employees: [
          { first_name: 'Marty', last_name: 'McFly' },
          { first_name: 'Doc', last_name: 'Brown' }
        ]
      })
    end
  end

  describe '#as_json' do
    it 'is like #serialize but takes an extra argument' do
      person_model = define_model(:Person) do
        property :first_name
        property :last_name
      end
      location_model = define_model(:Location) do
        property :lat, coerce: :float
        property :lng, coerce: :float
        property(:type, readonly: true, coerce: :symbol) { :residential }
      end
      store_model = define_model(:Store) do
        property :name
        property :location, coerce: location_model
        property(
          :supported_product_ids,
          coerce: Array[:integer]
        )
        property(
          :promotions_by_product_id,
          coerce: Hash[:integer => :big_decimal]
        )
        property :employees, coerce: Array[person_model]
      end
      store = store_model.new(
        name: 'Raleigh',
        location: { lat: 30.23, lng: -59.34 },
        supported_product_ids: [1, 2, 3],
        promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
        employees: [
          { first_name: 'Marty', last_name: 'McFly' },
          { first_name: 'Doc', last_name: 'Brown' }
        ]
      )

      expect(store.as_json({})).to eq({
        'name' => 'Raleigh',
        'location' => {
          'lat' => 30.23,
          'lng' => -59.34,
          'type' => 'residential'
        },
        'supported_product_ids' => [1, 2, 3],
        'promotions_by_product_id' => {
          10 => '30.4',
          15 => '84.3'
        },
        'employees' => [
          { 'first_name' => 'Marty', 'last_name' => 'McFly' },
          { 'first_name' => 'Doc', 'last_name' => 'Brown' }
        ]
      })
    end
  end

  describe '#==' do
    context 'given a hash' do
      context 'that is user-supplied' do
        context 'when the hash lines up exactly with the attributes of this HashStruct, considering readonly attributes, aliases, and nested HashStructs' do
          it 'returns true' do
            person_model = define_model(:Person) do
              property :first_name
              property :last_name
            end
            location_model = define_model(:Location) do
              property :lat, coerce: :float
              property :lng, coerce: :float
              property(:type, readonly: true, coerce: :symbol) { :residential }
            end
            store_model = define_model(:Store) do
              property :name
              property :location, aliases: [:geo_location], coerce: location_model
              property(
                :supported_product_ids,
                coerce: Array[:integer]
              )
              property(
                :promotions_by_product_id,
                coerce: Hash[:integer => :big_decimal]
              )
              property :employees, coerce: Array[person_model]
            end
            store = store_model.new(
              name: 'Raleigh',
              location: { lat: 30.23, lng: -59.34 },
              supported_product_ids: [1, 2, 3],
              promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
              employees: [
                { first_name: 'Marty', last_name: 'McFly' },
                { first_name: 'Doc', last_name: 'Brown' }
              ]
            )

            expect(store).to eq({
              name: 'Raleigh',
              'geo_location' => location_model.new(
                lat: 30.23,
                lng: -59.34
              ),
              supported_product_ids: [1, 2, 3],
              'promotions_by_product_id' => {
                10 => BigDecimal('30.4'),
                15 => BigDecimal('84.3')
              },
              employees: [
                { first_name: 'Marty', 'last_name' => 'McFly' },
                { first_name: 'Doc', last_name: 'Brown' }
              ]
            })
          end
        end

        context "which presumably represents a HashStruct's attributes but omits one of its readonly attributes" do
          it 'returns false' do
            model = define_model do
              property :name, aliases: [:full_name]
              property :age
              property(:gender, readonly: true) { :male }
            end

            instance = model.new(name: 'Elliot', age: 31)

            expect(instance).not_to eq({
              name: 'Elliot',
              age: 31
            })
          end
        end

        context "which presumably represents a HashStruct's attributes but doesn't match one of its readonly attributes" do
          it 'returns false' do
            model = define_model do
              property :name, aliases: [:full_name]
              property :age
              property(:gender, readonly: true) { :male }
            end

            instance = model.new(name: 'Elliot', age: 31)

            expect(instance).not_to eq({
              name: 'Elliot',
              age: 31,
              gender: 'female'
            })
          end
        end

        context "which cannot be turned into an instance of this HashStruct" do
          it 'returns false' do
            model = define_model { property :name }

            instance = model.new(name: 'Elliot')

            expect(instance).not_to eq(age: 31)
          end
        end
      end

      context 'that comes from #to_h' do
        it 'returns true' do
          person_model = define_model(:Person) do
            property :first_name
            property :last_name
          end
          location_model = define_model(:Location) do
            property :lat, coerce: :float
            property :lng, coerce: :float
            property(:type, readonly: true, coerce: :symbol) { :residential }
          end
          store_model = define_model(:Store) do
            property :name
            property :location, aliases: [:geo_location], coerce: location_model
            property(
              :supported_product_ids,
              coerce: Array[:integer]
            )
            property(
              :promotions_by_product_id,
              coerce: Hash[:integer => :big_decimal]
            )
            property :employees, coerce: Array[person_model]
          end
          store = store_model.new(
            name: 'Raleigh',
            location: { lat: 30.23, lng: -59.34 },
            supported_product_ids: [1, 2, 3],
            promotions_by_product_id: { 10 => '30.4', 15 => '84.3' },
            employees: [
              { first_name: 'Marty', last_name: 'McFly' },
              { first_name: 'Doc', last_name: 'Brown' }
            ]
          )

          expect(store).to eq(store.to_h)
        end
      end
    end
  end

  #---

  matcher :have_attribute do |attribute_name|
    attr_reader :model, :results

    chain :with_default, :default_value
    chain :that_maps, :values
    chain :reading_via, :way_to_read
    chain :writing_via, :way_to_write

    match do |model|
      @model = model

      results.all? do |result|
        result[:expected_output] == result[:actual_output]
      end
    end

    failure_message do
      "Expected #{model.class.name} to have an attribute :#{attribute_name} " +
        "that maps inputs to outputs.\nSome inputs did not match their " +
        "outputs:\n\n" +
        pretty_failed_results
    end

    define_method(:pretty_failed_results) do
      failed_results.map do |result|
        "* Expected #{result[:input].inspect} to map to " +
          "#{result[:expected_output]}, but it mapped to " +
          "#{result[:actual_output].inspect}"
      end.join("\n")
    end

    define_method(:failed_results) do
      results.select do |result|
        result[:expected_output] != result[:actual_output]
      end
    end

    define_method(:results) do
      @results ||= values.map do |input, expected_output|
        instance = instantiate_model_via(
          way_to_write,
          model,
          { attribute_name => input },
          defaults
        )
        actual_output = read_attribute_via(way_to_read, instance, attribute_name)
        {
          input: input,
          expected_output: expected_output,
          actual_output: actual_output
        }
      end
    end

    define_method(:defaults) do
      if default_value
        { attribute_name => default_value }
      else
        {}
      end
    end
  end

  matcher :reject_writing_attribute do |attribute_name|
    chain :with_default, :default_value
    chain :to, :input
    chain :via, :way_to_write
    chain :with, :expected_error_class, :expected_error_message

    attr_reader :model, :matcher

    match do |model|
      @model = model
      @matcher = raise_error(expected_error_class, expected_error_message)
      matcher.matches?(assigning_attribute)
    end

    failure_message do
      matcher.failure_message
    end

    define_method(:assigning_attribute) do
      lambda do
        instantiate_model_via(
          way_to_write,
          model,
          { attribute_name => input } ,
          defaults
        )
      end
    end

    define_method(:defaults) do
      if default_value
        { attribute_name => default_value }
      else
        {}
      end
    end
  end

  def instantiate_model_via(way_to_write, model, attributes, defaults = {})
    if way_to_write == :initializer
      model.new(attributes)
    else
      default_attributes = default_attributes_for(
        model,
        defaults,
        property_names: attributes.keys
      )
      instance = model.new(default_attributes)

      attributes.each do |name, value|
        instance.send(way_to_write, name, value)
      end

      instance
    end
  end

  def read_attribute_via(way_to_read, instance, attribute_name)
    if way_to_read == :method
      instance.send(attribute_name)
    else
      instance.send(way_to_read, attribute_name)
    end
  end

  def default_attributes_for(
    model,
    defaults,
    property_names: model.properties.map(&:name)
  )
    property_names.inject({}) do |hash, name|
      property = model.look_up_property!(name)

      if property.required?
        default_value = determine_default_for(
          property.coerce,
          name: name,
          defaults: defaults
        )
        hash.merge(name => default_value)
      else
        hash
      end
    end
  end

  def determine_default_for(coerce, name: nil, defaults: {})
    if defaults.include?(name)
      defaults[name]
    elsif (
      coerce &&
      coerce.is_a?(Class) &&
      coerce.ancestors.include?(described_class)
    )
      coerce.new(default_attributes_for(coerce, defaults))
    else
      case coerce
      when Array
        [determine_default_for(coerce.first)]
      when Hash
        default_key = determine_default_for(coerce.keys.first)
        default_value = determine_default_for(coerce.values.first)
        { default_key => default_value }
      when :big_decimal, :float, :integer
        0
      when :boolean
        true
      when :symbol
        :some_value
      when :time_in_utc
        '2020-01-01T00:00:00.000Z'
      else
        'some value'
      end
    end
  end

  def define_model(name = :TestHashStruct, &block)
    define_class(name, superclass: described_class, &block)
  end

  def define_class(name, superclass: nil, &block)
    args = [superclass].compact

    Class.new(*args) do
      singleton_class.class_eval do
        define_method(:name) { name.to_s }
      end

      if block
        class_eval(&block)
      end
    end
  end
end
