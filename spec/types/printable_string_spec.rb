# coding: utf-8
require_relative '../spec_helper'

module RASN1::Types

  describe PrintableString do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(PrintableString.type).to eq('PRINTABLE STRING')
      end
    end

    describe '#initialize' do
      it 'creates a PrintableString with default values' do
        printable = PrintableString.new(:printable)
        expect(printable).to be_primitive
        expect(printable).to_not be_optional
        expect(printable.asn1_class).to eq(:universal)
        expect(printable.default).to eq(nil)
      end
    end
    
    describe '#to_der' do
      it 'generates a DER string' do
        printable = PrintableString.new(:printable)
        printable.value = 'azerty'
        expect(printable.to_der).to eq(binary("\x13\x06azerty"))
      end

      it 'generates a DER string according to ASN.1 class' do
        printable = PrintableString.new(:printable, class: :context)
        printable.value = 'a'
        expect(printable.to_der).to eq(binary("\x93\x01a"))
      end

      it 'generates a DER string according to default' do
        printable = PrintableString.new(:printable, default: 'NOP')
        printable.value = 'NOP'
        expect(printable.to_der).to eq('')
        printable.value = 'N'
        expect(printable.to_der).to eq(binary("\x13\x01N"))
      end

      it 'generates a DER string according to optional' do
        printable = PrintableString.new(:printable, optional: true)
        printable.value = nil
        expect(printable.to_der).to eq('')
        printable.value = 'abc'
        expect(printable.to_der).to eq(binary("\x13\x03abc"))
      end

      it 'raises on illegal character' do
        printable = PrintableString.new(:printable)
        printable.value = ';'
        expect {printable.to_der }.to raise_error(RASN1::ASN1Error, /invalid char.*';'$/)
      end
    end

    describe '#parse!' do
      let(:printable) { PrintableString.new(:printable) }

      it 'parses a DER PRINTABLE STRING' do
        printable.parse!(binary("\x13\x031a="))
        expect(printable.value).to eq('1a=')
      end

      it 'raises on illegal character' do
        expect { printable.parse!(binary("\x13\x03ab;")) }.
          to raise_error(RASN1::ASN1Error, /invalid char.*';'$/)
      end
    end
  end
end
