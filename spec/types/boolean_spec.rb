require_relative '../spec_helper'

module Rasn1::Types

  describe Boolean do
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
  end
end


