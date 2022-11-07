RSpec.shared_examples_for 'a model that produces the same binary data when to_der is called' do |*args|
    let(:input_data) { valid_data }

    describe '#to_der' do
      it 'produces the same binary data when to_der is called' do
        expect(described_class.parse(input_data).to_der).to eq(input_data)
      end
    end
  end
