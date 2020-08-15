RSpec.describe HashStruct, '.discard_all_unrecognized_attributes=' do
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
