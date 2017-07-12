require_relative '../spec_helper'

module Rasn1::Types

  describe Integer do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Integer.type).to eq('INTEGER')
      end
    end

    describe '#initialize' do
      it 'creates an Integer with default values' do
        int = Integer.new(:int)
        expect(int).to be_primitive
        expect(int).to_not be_optional
        expect(int.asn1_class).to eq(:universal)
        expect(int.default).to eq(nil)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        int = Integer.new(:int)
        int.value = 42
        expect(int.to_der).to eq("\x02\x01\x2a".force_encoding('BINARY'))
        int.value = 65536
        expect(int.to_der).to eq("\x02\x03\x01\x00\x00".force_encoding('BINARY'))
        int.value = 255
        expect(int.to_der).to eq("\x02\x02\x00\xff".force_encoding('BINARY'))
        int.value = -1
        expect(int.to_der).to eq("\x02\x01\xff".force_encoding('BINARY'))
        int.value = -543210
        expect(int.to_der).to eq("\x02\x03\xf7\xb6\x16".force_encoding('BINARY'))
      end

      it 'generates a DER string according to ASN.1 class' do
        int = Integer.new(:int, class: :application)
        int.value = 16
        expect(int.to_der).to eq("\x42\x01\x10".force_encoding('BINARY'))
      end

      it 'generates a DER string according to default' do
        int = Integer.new(:int, default: 545)
        int.value = 545
        expect(int.to_der).to eq('')
        int.value = 65000
        expect(int.to_der).to eq("\x02\x03\x00\xfd\xe8".force_encoding('BINARY'))
      end

      it 'generates a DER string according to optional' do
        int = Integer.new(:int, optional: true)
        int.value = nil
        expect(int.to_der).to eq('')
        int.value = 545
        expect(int.to_der).to eq("\x02\x02\x02\x21".force_encoding('BINARY'))
      end
    end

   describe '#parse!' do
     let(:int) { Integer.new(:int) }

     it 'parses a DER INTEGER string' do
       int.parse!("\x02\x01\x00".force_encoding('BINARY'))
       expect(int.value).to eq(0)
       int.parse!("\x02\x02\x00\xff".force_encoding('BINARY'))
       expect(int.value).to eq(255)
       int.parse!("\x02\x03\x01\x00\x00".force_encoding('BINARY'))
       expect(int.value).to eq(65536)
       int.parse!("\x02\x01\xFF".force_encoding('BINARY'))
       expect(int.value).to eq(-1)
       int.parse!("\x02\x03\xf7\xb6\x16".force_encoding('BINARY'))
       expect(int.value).to eq(-543210)
     end
   end
  end
end


