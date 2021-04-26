require_relative '../spec_helper'

module RASN1::Types

  describe OctetString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(OctetString.type).to eq('OCTET STRING')
      end
    end

    describe '#initialize' do
      it 'creates a OctetString with default values' do
        os = OctetString.new
        expect(os).to be_primitive
        expect(os).to_not be_optional
        expect(os.asn1_class).to eq(:universal)
        expect(os.default).to eq(nil)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        os = OctetString.new
        os.value = 'NOP'
        expect(os.to_der).to eq(binary("\x04\x03NOP"))
      end

      it 'generates a DER string according to ASN.1 class' do
        os = OctetString.new(class: :context)
        os.value = 'a'
        expect(os.to_der).to eq(binary("\x84\x01a"))
      end

      it 'generates a DER string according to default' do
        os = OctetString.new(default: 'NOP')
        os.value = 'NOP'
        expect(os.to_der).to eq('')
        os.value = 'N'
        expect(os.to_der).to eq(binary("\x04\x01N"))
      end

      it 'generates a DER string according to optional' do
        os = OctetString.new(optional: true)
        os.value = nil
        expect(os.to_der).to eq('')
        os.value = 'abc'
        expect(os.to_der).to eq(binary("\x04\x03abc"))
      end

      it 'serializes a Types::Base object when set as value' do
        os = OctetString.new
        int = Integer.new
        int.value = 12
        os.value = int
        expect(os.to_der).to eq(binary("\x04\x03\x02\x01\x0c"))
      end
    end

    describe '#parse!' do
      let(:os) { OctetString.new }

      it 'parses a DER OCTET STRING' do
        os.parse!(binary("\x04\x02\x01\x02"))
        expect(os.value).to eq(binary("\x01\x02"))
      end
    end
  end
end
