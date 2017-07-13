require_relative '../spec_helper'

module Rasn1::Types

  describe BitString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(BitString.type).to eq('BIT STRING')
      end
    end

    describe '#initialize' do
      it 'creates a BitString with default values' do
        bs = BitString.new(:bs)
        expect(bs).to be_primitive
        expect(bs).to_not be_optional
        expect(bs.asn1_class).to eq(:universal)
        expect(bs.default).to eq(nil)
      end
    end
    
    describe '#to_der' do
      it 'raises if bit length is not set' do
        bs = BitString.new(:bs)
        bs.value = 'NOP'
        expect { bs.to_der }.to raise_error(Rasn1::ASN1Error)
      end

      it 'generates a DER string' do
        bs = BitString.new(:bs)
        bs.value = 'NOP'
        bs.bit_length = 20
        expect(bs.to_der).to eq("\x03\x04\x04NOP".force_encoding('BINARY'))
      end

      it 'adds zero bits if value size is lesser than bit length' do
        bs = BitString.new(:bs)
        bs.value = 'abc'
        bs.bit_length = 28
        expect(bs.to_der).to eq("\x03\x05\x04abc\x00".force_encoding('BINARY'))
      end

      it 'chops bits if value size is greater than bit length' do
        bs = BitString.new(:bs)
        bs.value = 'abc'
        bs.bit_length = 22
        expect(bs.to_der).to eq("\x03\x04\x02ab`".force_encoding('BINARY'))
        bs.value = 'abc'
        bs.bit_length = 16
        expect(bs.to_der).to eq("\x03\x03\x00ab".force_encoding('BINARY'))
      end

      it 'generates a DER string according to ASN.1 class' do
        bs = BitString.new(:bs, class: :context)
        bs.value = 'a'
        bs.bit_length = 8
        expect(bs.to_der).to eq("\x83\x02\x00a".force_encoding('BINARY'))
      end

      it 'generates a DER string according to default' do
        bs = BitString.new(:bs, default: 'NOP', bit_length: 22)
        bs.value = 'NOP'
        bs.bit_length = 22
        expect(bs.to_der).to eq('')
        bs.bit_length = 24
        expect(bs.to_der).to eq("\x03\x04\x00NOP".force_encoding('BINARY'))
        bs.value = 'N'
        bs.bit_length = 8
        expect(bs.to_der).to eq("\x03\x02\x00N".force_encoding('BINARY'))
      end

      it 'generates a DER string according to optional' do
        bs = BitString.new(:bs, optional: true)
        bs.value = nil
        expect(bs.to_der).to eq('')
        bs.bit_length = 43
        expect(bs.to_der).to eq('')
        bs.value = 'abc'
        bs.bit_length = 24
        expect(bs.to_der).to eq("\x03\x04\x00abc".force_encoding('BINARY'))
      end
    end

    describe '#parse!' do
      let(:bs) { BitString.new(:bs) }

      it 'parses a DER BIT STRING' do
        bs.parse!("\x03\x03\x00\x01\x02".force_encoding('BINARY'))
        expect(bs.value).to eq("\x01\x02".force_encoding('BINARY'))
        expect(bs.bit_length).to eq(16)
        bs.parse!("\x03\x03\x01\x01\x02".force_encoding('BINARY'))
        expect(bs.value).to eq("\x01\x02".force_encoding('BINARY'))
        expect(bs.bit_length).to eq(15)
        bs.parse!("\x03\x03\x07\x01\x80".force_encoding('BINARY'))
        expect(bs.value).to eq("\x01\x80".force_encoding('BINARY'))
        expect(bs.bit_length).to eq(9)
      end
    end
  end
end
