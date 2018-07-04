require_relative '../spec_helper'

module RASN1::Types

  describe Null do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Null.type).to eq('NULL')
      end
    end

    describe '#initialize' do
      it 'creates an Null with default values' do
        null = Null.new
        expect(null).to be_primitive
        expect(null).to_not be_optional
        expect(null.asn1_class).to eq(:universal)
        expect(null.default).to eq(nil)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        null = Null.new
        expect(null.to_der).to eq(binary("\x05\x00"))
        null.value = 'abcd'
        expect(null.to_der).to eq(binary("\x05\x00"))
      end
    end

    describe '#parse!' do
      let(:null) { Null.new }

      it 'parses a NULL DER string' do
        null.parse!(binary("\x05\x00"))
        expect(null.value).to be_nil
      end

      it 'raises on malformed NULL tag' do
        der = binary("\x05\x01\x01")
        expect { null.parse!(der) }.to raise_error(RASN1::ASN1Error, /not have content/)
      end
    end

    describe '#inspect' do
      it 'returns inspect string' do
        expect(Null.new.inspect).to eq('NULL')
        expect(Null.new(name: :data).inspect).to eq('data NULL')
        expect(Null.new(optional: true).inspect).to eq('NULL OPTIONAL')
      end
    end
  end
end
