RSpec.describe HashStruct, '.after_writing_attribute' do
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
