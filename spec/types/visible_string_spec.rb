# coding: utf-8
require_relative '../spec_helper'

module RASN1::Types

  describe VisibleString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(VisibleString.type).to eq('VISIBLE STRING')
      end
    end

    describe '#initialize' do
      it 'creates a VisibleString with default values' do
        visible = VisibleString.new(:visible)
        expect(visible).to be_primitive
        expect(visible).to_not be_optional
        expect(visible.asn1_class).to eq(:universal)
        expect(visible.default).to eq(nil)
      end
    end
    
    describe '#to_der' do
      it 'generates a DER string' do
        visible = VisibleString.new(:visible)
        visible.value = 'azerty,;:'
        expect(visible.to_der).to eq(binary("\x1a\x09azerty,;:"))
      end

      it 'generates a DER string according to ASN.1 class' do
        visible = VisibleString.new(:visible, class: :context)
        visible.value = 'a'
        expect(visible.to_der).to eq(binary("\x9a\x01a"))
      end

      it 'generates a DER string according to default' do
        visible = VisibleString.new(:visible, default: 'NOP', octet_length: 22)
        visible.value = 'NOP'
        expect(visible.to_der).to eq('')
        visible.value = 'N'
        expect(visible.to_der).to eq(binary("\x1a\x01N"))
      end

      it 'generates a DER string according to optional' do
        visible = VisibleString.new(:visible, optional: true)
        visible.value = nil
        expect(visible.to_der).to eq('')
        visible.value = 'abc'
        expect(visible.to_der).to eq(binary("\x1a\x03abc"))
      end
    end

    describe '#parse!' do
      let(:visible) { VisibleString.new(:visible) }

      it 'parses a DER VISIBLE STRING' do
        visible.parse!(binary("\x1a\x04!:;,"))
        expect(visible.value).to eq('!:;,')
      end
    end
  end
end
