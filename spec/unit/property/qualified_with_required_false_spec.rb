RSpec.describe HashStruct, '.property' do
  context 'qualified with required: false' do
    it 'does not raise an error on instantiation when the attribute is not set' do
      model = define_model { property :name, required: false }
      instantiating_model = -> { model.new }

      expect(&instantiating_model).not_to raise_error
    end
  end
end
