# coding: utf-8
# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1::Types
  describe VisibleString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(VisibleString.type).to eq('VisibleString')
      end
    end

    describe '#initialize' do
      it 'creates a VisibleString with default values' do
        vs = VisibleString.new
        expect(vs).to be_primitive
        expect(vs).to_not be_optional
        expect(vs.asn1_class).to eq(:universal)
        expect(vs.default).to eq(nil)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        vs = VisibleString.new(value: 'azerty')
        expect(vs.to_der).to eq("\x1a\x06azerty".b)
      end

      it 'generates a DER string according to ASN.1 class' do
        vs = VisibleString.new(value: 'a', class: :context)
        expect(vs.to_der).to eq("\x9a\x01a".b)
      end

      it 'generates a DER string according to default' do
        vs = VisibleString.new(default: 'NOP')
        vs.value = 'NOP'
        expect(vs.to_der).to eq('')
        vs.value = 'N'
        expect(vs.to_der).to eq("\x1a\x01N".b)
      end

      it 'generates a DER string according to optional' do
        vs = VisibleString.new(optional: true)
        vs.value = nil
        expect(vs.to_der).to eq('')
        vs.value = 'abc'
        expect(vs.to_der).to eq("\x1a\x03abc".b)
      end
    end

    describe '#value=' do
      it 'raises when including a non-visible character' do
        vs = VisibleString.new
        expect { vs.value = 1.chr }.to raise_error(RASN1::ConstraintError)
      end
    end

    describe '#parse!' do
      let(:vs) { VisibleString.new }

      it 'parses a DER VisibleString' do
        vs.parse!("\x1a\x04\x31\x32\x33\x34".b)
        expect(vs.value).to eq('1234')
        expect(vs.value.encoding).to eq(Encoding::US_ASCII)
      end

      it 'raises when parsing a DER string containing a non-visible character' do
        expect {vs.parse!("\x1a\x01\x01".b)}.to raise_error(RASN1::ConstraintError)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
