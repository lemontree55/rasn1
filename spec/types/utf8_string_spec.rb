# coding: utf-8
# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
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
        utf8 = Utf8String.new(value: 'azertyù€')
        expect(utf8.to_der).to eq("\x0c\x0bazertyù€".b)
      end

      it 'generates a DER string according to ASN.1 class' do
        utf8 = Utf8String.new(value: 'a', class: :context)
        expect(utf8.to_der).to eq("\x8c\x01a".b)
      end

      it 'generates a DER string according to default' do
        utf8 = Utf8String.new(default: 'NOP', octet_length: 22)
        utf8.value = 'NOP'
        expect(utf8.to_der).to eq('')
        utf8.value = 'N'
        expect(utf8.to_der).to eq("\x0c\x01N".b)
      end

      it 'generates a DER string according to optional' do
        utf8 = Utf8String.new(optional: true)
        utf8.value = nil
        expect(utf8.to_der).to eq('')
        utf8.value = 'abc'
        expect(utf8.to_der).to eq("\x0c\x03abc".b)
      end
    end

    describe '#parse!' do
      let(:utf8) { Utf8String.new }

      it 'parses a DER UTF8 STRING' do
        utf8.parse!("\x0c\x04\x31\xe2\x82\xac".b)
        expect(utf8.value).to eq('1€')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
