require_relative '../spec_helper'

module RASN1::Types

  describe BitString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(BitString.type).to eq('BIT STRING')
      end
    end

    describe '#initialize' do
      it 'creates a BitString with default values' do
        bs = BitString.new
        expect(bs).to be_primitive
        expect(bs).to_not be_optional
        expect(bs.asn1_class).to eq(:universal)
        expect(bs.default).to eq(nil)
      end

      it 'raises if bit_length option is not set when default value is set' do
        expect { BitString.new(default: '123') }.to raise_error(RASN1::ASN1Error)
      end
    end
    
    describe '#to_der' do
      it 'raises if bit length is not set' do
        bs = BitString.new
        bs.value = 'NOP'
        expect { bs.to_der }.to raise_error(RASN1::ASN1Error)
      end

      it 'generates a DER string' do
        bs = BitString.new
        bs.value = 'NOP'
        bs.bit_length = 20
        expect(bs.to_der).to eq(binary("\x03\x04\x04NOP"))
      end

      it 'adds zero bits if value size is lesser than bit length' do
        bs = BitString.new
        bs.value = 'abc'
        bs.bit_length = 28
        expect(bs.to_der).to eq(binary("\x03\x05\x04abc\x00"))
      end

      it 'chops bits if value size is greater than bit length' do
        bs = BitString.new
        bs.value = 'abc'
        bs.bit_length = 22
        expect(bs.to_der).to eq(binary("\x03\x04\x02ab`"))
        bs.value = 'abc'
        bs.bit_length = 16
        expect(bs.to_der).to eq(binary("\x03\x03\x00ab"))
      end

      it 'generates a DER string according to ASN.1 class' do
        bs = BitString.new(class: :context)
        bs.value = 'a'
        bs.bit_length = 8
        expect(bs.to_der).to eq(binary("\x83\x02\x00a"))
      end

      it 'generates a DER string according to default' do
        bs = BitString.new(default: 'NOP', bit_length: 22)
        bs.value = 'NOP'
        bs.bit_length = 22
        expect(bs.to_der).to eq('')
        bs.bit_length = 24
        expect(bs.to_der).to eq(binary("\x03\x04\x00NOP"))
        bs.value = 'N'
        bs.bit_length = 8
        expect(bs.to_der).to eq(binary("\x03\x02\x00N"))
      end

      it 'generates a DER string according to optional' do
        bs = BitString.new(optional: true)
        bs.value = nil
        expect(bs.to_der).to eq('')
        bs.bit_length = 43
        expect(bs.to_der).to eq('')
        bs.value = 'abc'
        bs.bit_length = 24
        expect(bs.to_der).to eq(binary("\x03\x04\x00abc"))
      end
    end

    describe '#parse!' do
      let(:bs) { BitString.new }

      it 'parses a DER BIT STRING' do
        bs.parse!(binary("\x03\x03\x00\x01\x02"))
        expect(bs.value).to eq(binary("\x01\x02"))
        expect(bs.bit_length).to eq(16)
        bs.parse!(binary("\x03\x03\x01\x01\x02"))
        expect(bs.value).to eq(binary("\x01\x02"))
        expect(bs.bit_length).to eq(15)
        bs.parse!(binary("\x03\x03\x07\x01\x80"))
        expect(bs.value).to eq(binary("\x01\x80"))
        expect(bs.bit_length).to eq(9)
      end
    end
  end
end
