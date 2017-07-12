require_relative '../spec_helper'

module Rasn1::Types

  describe Boolean do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Boolean.type).to eq('BOOLEAN')
      end
    end

    describe '#initialize' do
      it 'creates a Boolean with default values' do
        bool = Boolean.new(:bool)
        expect(bool).to be_primitive
        expect(bool).to_not be_optional
        expect(bool.asn1_class).to eq(:universal)
        expect(bool.default).to eq(nil)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        bool = Boolean.new(:bool)
        bool.value = true
        expect(bool.to_der).to eq("\x01\x01\xff".force_encoding('BINARY'))
        bool.value = false
        expect(bool.to_der).to eq("\x01\x01\x00".force_encoding('BINARY'))
      end

      it 'generates a DER string according to ASN.1 class' do
        bool = Boolean.new(:bool, class: :private)
        bool.value = true
        expect(bool.to_der).to eq("\xC1\x01\xff".force_encoding('BINARY'))
      end

      it 'generates a DER string according to default' do
        bool = Boolean.new(:bool, default: true)
        bool.value = true
        expect(bool.to_der).to eq('')
        bool.value = false
        expect(bool.to_der).to eq("\x01\x01\x00".force_encoding('BINARY'))
      end

      it 'generates a DER string according to optional' do
        bool = Boolean.new(:bool, optional: true)
        bool.value = nil
        expect(bool.to_der).to eq('')
        bool.value = true
        expect(bool.to_der).to eq("\x01\x01\xff".force_encoding('BINARY'))
      end
    end

    describe '#parse!' do
      let(:bool) { Boolean.new(:bool) }
      let(:ber) { "\x01\x01\x56".force_encoding('BINARY') }

      it 'parses a DER BOOLEAN string' do
        bool.parse!("\x01\x01\x00".force_encoding('BINARY'))
        expect(bool.value).to be(false)
        bool.parse!("\x01\x01\xFF".force_encoding('BINARY'))
        expect(bool.value).to be(true)
      end

      it 'parses a BER BOOLEAN string if ber parameter is true' do
        bool.parse!(ber, ber: true)
        expect(bool.value).to be(true)
      end

      it 'raises on a BER BOOLEAN string if ber parameter is not set' do
        expect { bool.parse!(ber) }.to raise_error(Rasn1::ASN1Error, /bad value 0x56/)
      end
    end
  end
end


