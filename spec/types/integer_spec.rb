require_relative '../spec_helper'

module RASN1::Types

  describe Integer do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Integer.type).to eq('INTEGER')
      end
    end

    describe '#initialize' do
      it 'creates an Integer with default values' do
        int = Integer.new
        expect(int).to be_primitive
        expect(int).to_not be_optional
        expect(int.asn1_class).to eq(:universal)
        expect(int.default).to eq(nil)
      end
    end

    describe '#to_i' do
      it 'gets ruby Integer object' do
        int = Integer.new(53)
        expect(int.to_i).to eq(53)
      end

      it 'gets default value is one is defined and not value was set' do
        int = Integer.new(default: 123456)
        expect(int.to_i).to eq(123456)
        int.value = 12
        expect(int.to_i).to eq(12)
      end

      it 'returns 0 if no default value nor value were set' do
        expect(Integer.new.to_i).to eq(0)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        int = Integer.new
        int.value = 42
        expect(int.to_der).to eq(binary("\x02\x01\x2a"))
        int.value = 65536
        expect(int.to_der).to eq(binary("\x02\x03\x01\x00\x00"))
        int.value = 255
        expect(int.to_der).to eq(binary("\x02\x02\x00\xff"))
        int.value = -1
        expect(int.to_der).to eq(binary("\x02\x01\xff"))
        int.value = -543210
        expect(int.to_der).to eq(binary("\x02\x03\xf7\xb6\x16"))
      end

      it 'generates a DER string according to ASN.1 class' do
        int = Integer.new(class: :application)
        int.value = 16
        expect(int.to_der).to eq(binary("\x42\x01\x10"))
      end

      it 'generates a DER string according to default' do
        int = Integer.new(default: 545)
        int.value = 545
        expect(int.to_der).to eq('')
        int.value = 65000
        expect(int.to_der).to eq(binary("\x02\x03\x00\xfd\xe8"))
      end

      it 'generates a DER string according to optional' do
        int = Integer.new(optional: true)
        int.value = nil
        expect(int.to_der).to eq('')
        int.value = 545
        expect(int.to_der).to eq(binary("\x02\x02\x02\x21"))
      end
    end

   describe '#parse!' do
     let(:int) { Integer.new }

     it 'parses a DER INTEGER string' do
       int.parse!(binary("\x02\x01\x00"))
       expect(int.value).to eq(0)
       int.parse!(binary("\x02\x02\x00\xff"))
       expect(int.value).to eq(255)
       int.parse!(binary("\x02\x03\x01\x00\x00"))
       expect(int.value).to eq(65536)
       int.parse!(binary("\x02\x01\xFF"))
       expect(int.value).to eq(-1)
       int.parse!(binary("\x02\x03\xf7\xb6\x16"))
       expect(int.value).to eq(-543210)
     end
   end
  end
end
