# coding: utf-8
require_relative '../spec_helper'

module RASN1::Types

  describe Utf8String do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Utf8String.type).to eq('UTF8String')
      end
    end

    describe '#initialize' do
      it 'creates a Utf8String with default values' do
        utf8 = Utf8String.new
        expect(utf8).to be_primitive
        expect(utf8).to_not be_optional
        expect(utf8.asn1_class).to eq(:universal)
        expect(utf8.default).to eq(nil)
      end
    end
    
    describe '#to_der' do
      it 'generates a DER string' do
        utf8 = Utf8String.new('azertyù€')
        expect(utf8.to_der).to eq(binary("\x0c\x0bazertyù€"))
      end

      it 'generates a DER string according to ASN.1 class' do
        utf8 = Utf8String.new('a', class: :context)
        expect(utf8.to_der).to eq(binary("\x8c\x01a"))
      end

      it 'generates a DER string according to default' do
        utf8 = Utf8String.new(default: 'NOP', octet_length: 22)
        utf8.value = 'NOP'
        expect(utf8.to_der).to eq('')
        utf8.value = 'N'
        expect(utf8.to_der).to eq(binary("\x0c\x01N"))
      end

      it 'generates a DER string according to optional' do
        utf8 = Utf8String.new(optional: true)
        utf8.value = nil
        expect(utf8.to_der).to eq('')
        utf8.value = 'abc'
        expect(utf8.to_der).to eq(binary("\x0c\x03abc"))
      end
    end

    describe '#parse!' do
      let(:utf8) { Utf8String.new }

      it 'parses a DER UTF8 STRING' do
        utf8.parse!(binary("\x0c\x04\x31\xe2\x82\xac"))
        expect(utf8.value).to eq('1€')
      end
    end
  end
end
