RSpec.describe HashStruct, '.property' do
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
end
