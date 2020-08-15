RSpec.describe HashStruct, '.property' do
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
end
