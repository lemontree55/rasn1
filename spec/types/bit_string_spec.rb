# frozen_string_literal: true

require_relative '../spec_helper'

module RASN2::Types # rubocop:disable Metrics/ModuleLength
  describe BitString do # rubocop:disable Metrics/BlockLength
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
        expect { BitString.new(default: '123') }.to raise_error(RASN2::ASN1Error)
      end
    end

    describe '#to_der' do # rubocop:disable Metrics/BlockLength
      it 'raises if bit length is not set' do
        bs = BitString.new
        bs.value = 'NOP'
        expect { bs.to_der }.to raise_error(RASN2::ASN1Error)
      end

      it 'generates a DER string with unfrozen strings' do
        bs = BitString.new
        bs.value = +'NOP'
        bs.bit_length = 20
        expect(bs.to_der).to eq("\x03\x04\x04NOP".b)
      end

      it 'generates a DER string with frozen strings' do
        bs = BitString.new
        bs.value = 'NOP'
        bs.bit_length = 20
        expect(bs.to_der).to eq("\x03\x04\x04NOP".b)
      end

      it 'adds zero bits if value size is lesser than bit length' do
        bs = BitString.new
        bs.value = 'abc'
        bs.bit_length = 28
        expect(bs.to_der).to eq("\x03\x05\x04abc\x00".b)
      end

      it 'chops bits if value size is greater than bit length' do
        bs = BitString.new
        bs.value = 'abc'
        bs.bit_length = 22
        expect(bs.to_der).to eq("\x03\x04\x02ab`".b)
        bs.value = 'abc'
        bs.bit_length = 16
        expect(bs.to_der).to eq("\x03\x03\x00ab".b)
      end

      it 'generates a DER string according to ASN.1 class' do
        bs = BitString.new(class: :context)
        bs.value = 'a'
        bs.bit_length = 8
        expect(bs.to_der).to eq("\x83\x02\x00a".b)
      end

      it 'generates a DER string according to default' do
        bs = BitString.new(default: 'NOP', bit_length: 22)
        bs.value = 'NOP'
        bs.bit_length = 22
        expect(bs.to_der).to eq('')
        bs.bit_length = 24
        expect(bs.to_der).to eq("\x03\x04\x00NOP".b)
        bs.value = 'N'
        bs.bit_length = 8
        expect(bs.to_der).to eq("\x03\x02\x00N".b)
      end

      it 'generates a DER string according to optional' do
        bs = BitString.new(optional: true)
        bs.value = nil
        expect(bs.to_der).to eq('')
        bs.bit_length = 43
        expect(bs.to_der).to eq('')
        bs.value = 'abc'
        bs.bit_length = 24
        expect(bs.to_der).to eq("\x03\x04\x00abc".b)
      end
    end

    describe '#parse!' do
      let(:bs) { BitString.new }

      it 'parses a DER BIT STRING' do
        bs.parse!("\x03\x03\x00\x01\x02".b)
        expect(bs.value).to eq("\x01\x02".b)
        expect(bs.bit_length).to eq(16)
        bs.parse!("\x03\x03\x01\x01\x02".b)
        expect(bs.value).to eq("\x01\x02".b)
        expect(bs.bit_length).to eq(15)
        bs.parse!("\x03\x03\x07\x01\x80".b)
        expect(bs.value).to eq("\x01\x80".b)
        expect(bs.bit_length).to eq(9)
      end
    end




    shared_examples :inspect do |color|
      include RASN2::Helpers::Colorize

      before :each do
        Rainbow.enabled = color
      end

      it 'gets inspect string' do
        bs = BitString.new(value: 'abcd', bit_length: 30)
        expect(bs.inspect(color: color)).to eq("#{colorize_class('BIT STRING')}: (bit length: 30): \"abcd\"")
      end

      it 'gets inspect string with name' do
        bs = BitString.new(value: 'abcd', name: :bs, bit_length: 30)
        expect(bs.inspect(color: color)).to eq("#{colorize_name('bs')} #{colorize_class('BIT STRING')}: (bit length: 30): \"abcd\"")
      end
    end

    context 'with color' do
      it_behaves_like :inspect, true
    end

    context 'without color' do
      it_behaves_like :inspect, false
    end


  end
end
