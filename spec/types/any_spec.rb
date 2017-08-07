# coding: utf-8
require_relative '../spec_helper'

class AnyModel < RASN1::Model
  sequence :seq,
           content: [any(:data), objectid(:id)]
end

module RASN1::Types


  describe Any do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Any.type).to eq('ANY')
      end
    end

    describe '#to_der' do
    end

    describe '#parse!' do
      it 'parses any sequence with 2 elements and the second one is an OBJECT ID' do
        der = binary("\x30\x0a\x04\x03abc\x06\x03\x2a\x03\x04")
        anymodel = AnyModel.parse(der)
        expect(anymodel[:id].value).to eq('1.2.3.4')
        expect(anymodel[:data].value).to eq(binary("\x04\x03abc"))

        der = binary("\x30\x09\x02\x02\x00\x80\x06\x03\x2a\x03\x05")
        anymodel = AnyModel.parse(der)
        expect(anymodel[:id].value).to eq('1.2.3.5')
        expect(anymodel[:data].value).to eq(binary("\x02\x02\x00\x80"))
      end
    end
  end
end

