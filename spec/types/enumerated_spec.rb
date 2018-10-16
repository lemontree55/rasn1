require_relative '../spec_helper'

module RASN1::Types

  describe Enumerated do

    let(:enumerated) { { a: 0, b: 1, c: 2 } }

    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Enumerated.type).to eq('ENUMERATED')
      end
    end

    describe '#initialize' do
      it 'creates an Enumerated with default values' do
        enum = Enumerated.new(enum: enumerated)
        expect(enum).to be_primitive
        expect(enum).to_not be_optional
        expect(enum.asn1_class).to eq(:universal)
        expect(enum.default).to eq(nil)
      end

      it 'raises when enum key is absent' do
        expect { Enumerated.new(:enum) }.to raise_error(RASN1::EnumeratedError,
                                                        'no enumeration given')
      end

      it 'raises on unknown default value' do
        expect { Enumerated.new(enum: enumerated, default: 53)}.
          to raise_error(RASN1::EnumeratedError, /default value/)
        expect { Enumerated.new(enum: enumerated, default: :e)}.
          to raise_error(RASN1::EnumeratedError, /default value/)
        expect { Enumerated.new(enum: enumerated, default: Object.new)}.
          to raise_error(TypeError, /default value/)
      end

      it 'records integer default value as name' do
        enum = Enumerated.new(enum: enumerated, default: 0)
        expect(enum.default).to eq(:a)
      end

      it 'records named default value as name' do
        enum = Enumerated.new(enum: enumerated, default: :b)
        expect(enum.default).to eq(:b)
      end
    end

    describe '#value=' do
      let(:enum) { Enumerated.new(enum: enumerated) }

      it 'sets known integer' do
        expect { enum.value = 1 }.to_not raise_error
      end

      it 'sets known name' do
        expect { enum.value = :c }.to_not raise_error
        expect(enum.value).to eq(:c)
      end

      it 'always records value as name' do
        enum.value = 2
        expect(enum.value).to eq(:c)
        enum.value = :b
        expect(enum.value).to eq(:b)
      end

      it 'raises on unknown integer' do
        expect { enum.value = 43 }.to raise_error(RASN1::EnumeratedError,
                                                  /not in enumeration/)
      end

      it 'raises on unknown name' do
        expect { enum.value = :d }.to raise_error(RASN1::EnumeratedError,
                                                  /unknwon enumerated value/)
      end

      it 'raises on setting object which is not an Integer nor a String nor a Symbol' do
        expect { enum.value = Object.new }.to raise_error(RASN1::EnumeratedError,
                                                          /not in enumeration/)
      end
    end

    describe '#to_i' do
      it 'gets ruby integer object' do
        enum = Enumerated.new(enum: enumerated)
        enum.value = 1
        expect(enum.to_i).to eq(1)
      end

      it 'gets default value if one is defined and not value was set' do
        enum = Enumerated.new(enum: enumerated, default: :c)
        expect(enum.to_i).to eq(2)
        enum.value = :a
        expect(enum.to_i).to eq(0)
      end

      it 'returns 0 if no default value nor value were set' do
        expect(Enumerated.new(enum: enumerated).to_i).to eq(0)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        enum = Enumerated.new(enum: enumerated)
        enum.to_h.each do |name, int|
          enum.value = name
          expect(enum.to_der).to eq([10, 1, int].pack('C3'))
        end
      end

      it 'generates a DER string according to ASN.1 class' do
        enum = Enumerated.new(enum: enumerated, class: :application)
        enum.value = :a
        expect(enum.to_der).to eq(binary("\x4a\x01\x00"))
      end

      it 'generates a DER string according to default' do
        enum = Enumerated.new(enum: enumerated, default: :a)
        enum.value = :a
        expect(enum.to_der).to eq('')
        enum.value = :b
        expect(enum.to_der).to eq(binary("\x0a\x01\x01"))
      end

      it 'generates a DER string according to optional' do
        enum = Enumerated.new(enum: enumerated, optional: true)
        enum.value = nil
        expect(enum.to_der).to eq('')
        enum.value = :c
        expect(enum.to_der).to eq(binary("\x0a\x01\x02"))
      end
    end

   describe '#parse!' do
     let(:enum) { Enumerated.new(enum: enumerated) }

     it 'parses a DER ENUMERATED string' do
       enum.to_h.each do |name, int|
         enum.parse!([10, 1, int].pack('C3'))
         expect(enum.value).to eq(name)
       end
     end
   end
  end
end
