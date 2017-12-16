require_relative '../spec_helper'

module RASN1::Types

  describe Base do

    describe '#initialize' do
      it 'sets value' do
        base = Base.new('value')
        expect(base.value).to eq('value')
        expect(base.optional?).to be(false)
        expect(base.default).to be(nil)
      end

      it 'accepts options' do
        expect { Base.new(opt1: 1, opt2: 2) }.to_not raise_error
      end

      it 'sets class option' do
        Base::CLASSES.keys.each do |asn1_class|
          base = Base.new(class: asn1_class)
          expect(base.asn1_class).to eq(asn1_class)
        end
      end

      it 'raises on unknown class' do
        expect { Base.new(class: :unknown) }.to raise_error(RASN1::ClassError)
        expect { Base.new(class: 'not a symbol') }.to raise_error(RASN1::ClassError)
      end

      it 'sets optional option' do
        base = Base.new(optional: true)
        expect(base.optional?).to be(true)
        base = Base.new(optional: 12)
        expect(base.optional?).to be(true)
        base = Base.new(optional: nil)
        expect(base.optional?).to be(false)
      end

      it 'sets default option' do
        base = Base.new(default: '123')
        expect(base.default).to eq('123')
      end

      it 'accepts a value' do
        int = Integer.new(value: 155)
        expect(int.value).to eq(155)
      end
    end

    describe '#to_der' do
      it 'should encode long length' do
        os = OctetString.new
        os.value = binary("\x00") * 65537
        os_der = os.to_der
        expect(os_der[1, 4]).to eq(binary("\x83\x01\x00\x01"))
        expect(os_der[5, os_der.length]).to eq(os.value)
      end

      it 'should raise on multi-byte tag' do
        int = Integer.new(implicit: 43)
        int.value = 0
        expect { int.to_der }.to raise_error(RASN1::ASN1Error, /multi-byte/)
      end
    end

    describe '#primitive?' do
      it 'returns false' do
        expect(Base.new.primitive?).to be(false)
      end
    end
    
    describe '#constructed?' do
      it 'returns false' do
        expect(Base.new.constructed?).to be(false)
      end
    end

    describe '#parse!' do
      let(:unexpected_der) { binary("\x02\x02\xca\xfe") }

      it 'raises on unexpected tag value' do
        bool = Boolean.new
        expect { bool.parse!(unexpected_der) }.to raise_error(RASN1::ASN1Error).
          with_message('Expected UNIVERSAL PRIMITIVE BOOLEAN but get UNIVERSAL PRIMITIVE INTEGER')
      end

      it 'does not raise on unexpected tag value with OPTIONAL tag' do
        bool = Boolean.new(optional: true)
        expect { bool.parse!(unexpected_der) }.to_not raise_error
        expect(bool.value).to be(nil)
      end

      it 'does not raise on unexpected tag value with DEFAULT tag' do
        bool = Boolean.new(default: false)
        expect { bool.parse!(unexpected_der) }.to_not raise_error
      end

      it 'sets value to default one when parsing an unexpected tag with DEFAULT one' do
        bool = Boolean.new(default: false)
        bool.parse!(unexpected_der)
        expect(bool.value).to be(false)
      end

      it 'parses tags with multi-byte length' do
        bs = BitString.new

        der = "\x03\x82\x01\x03\x00" + 'a' * 0x102
        expect(bs.parse!(der)).to eq(0x107)
        expect(bs.value).to eq('a' * 0x102)
        expect(bs.bit_length).to eq(0x102 * 8)
      end

      it 'returns total number of parsed bytes' do
        int = Integer.new
        bytes = int.parse!(binary("\x02\x01\x01"))
        expect(bytes).to eq(3)
        expect(int.value).to eq(1)
        bytes = int.parse!(binary("\x02\x01\x01\x02"))
        expect(bytes).to eq(3)
        expect(int.value).to eq(1)
      end

      it 'raises on indefinite length with primitive types' do
        bool = Boolean.new
        der = binary("\x01\x80\xff\x00\x00")
        expect { bool.parse!(der) }.to raise_error(RASN1::ASN1Error).
          with_message('malformed BOOLEAN TAG: indefinite length forbidden for primitive types')
      end

      context 'raises on indefinite length with constructed types' do
        let(:der) { binary("\x30\x80\x01\x01\xFF\x00\x00") }
        let(:seq) { seq = Sequence.new; seq.value = [Boolean.new]; seq }

        it 'on DER encoding' do
          expect { seq.parse!(der) }.to raise_error(RASN1::ASN1Error)
        end

        it 'on BER encoding' do
          expect { seq.parse!(der, ber: true) }.to raise_error(NotImplementedError)
        end
      end
    end

    context 'tagged types' do
      describe '#initialize' do
        it 'creates an explicit tagged type' do
          type = Integer.new(explicit: 5)
          expect(type.tagged?).to be(true)
          expect(type.constructed?).to be(false)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:context)
          expect(type.tag).to eq(0x85)
        end

        it 'creates an explicit application tagged type' do
          type = Integer.new(explicit: 0, class: :application)
          expect(type.tagged?).to be(true)
          expect(type.constructed?).to be(false)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:application)
          expect(type.tag).to eq(0x40)
        end

        it 'creates an explicit private tagged type' do
          type = Integer.new(explicit: 15, class: :private)
          expect(type.tagged?).to be(true)
          expect(type.constructed?).to be(false)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:private)
          expect(type.tag).to eq(0xcf)
        end

        it 'creates an explicit constructed tagged type' do
          type = Integer.new(explicit: 1, constructed: true, value: 2)
          expect(type.tagged?).to be(true)
          expect(type.constructed?).to be(true)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:context)
          expect(type.tag).to eq(0xa1)
        end

        it 'creates an implicit tagged type' do
          type = Integer.new(implicit: 5)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:context)
          expect(type.tag).to eq(0x85)
        end

        it 'creates an implicit application tagged type' do
          type = Integer.new(implicit: 0, class: :application)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:application)
          expect(type.tag).to eq(0x40)
        end

        it 'creates an implicit private tagged type' do
          type = Integer.new(implicit: 15, class: :private)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:private)
          expect(type.tag).to eq(0xcf)
        end
      end

      describe '#to_der' do
        it 'creates a DER string with explicit tagged type' do
          type = Integer.new(explicit: 5, value: 48)
          expect(type.to_der).to eq(binary("\x85\x03\x02\x01\x30"))

          type = Integer.new(explicit: 5, constructed: true, value: 48)
          expect(type.to_der).to eq(binary("\xa5\x03\x02\x01\x30"))
        end

        it 'creates a DER string with implicit tagged type' do
          type = Integer.new(implicit: 5)
          type.value = 48
          expect(type.to_der).to eq(binary("\x85\x01\x30"))
        end
      end

      describe '#parse!' do
        it 'parses a DER string with explicit tagged type' do
          type = Integer.new(explicit: 5)
          type.parse!(binary("\x85\x03\x02\x01\x30"))
          expect(type.value).to eq(48)
        end

        it 'parses a DER string with explicit constructed tagged type' do
          type = Integer.new(explicit: 5, constructed: true)
          type.parse!(binary("\xa5\x03\x02\x01\x30"))
          expect(type.value).to eq(48)
        end

        it 'parses a DER string with explicit tagged type with default value' do
          type = Enumerated.new(explicit: 0, constructed: true,
                                enum: { 'v1' => 0, 'v2' => 1, 'v3' => 2 },
                                default: 0)
          type.parse!(binary("\xa0\x03\x02\x01\x02"))
          expect(type.value).to eq('v3')
          type.parse!('')
          expect(type.value).to eq('v1')
        end

        it 'parses a DER string with implicit tagged type' do
          type = Integer.new(implicit: 5)
          type.parse!(binary("\x85\x01\x30"))
          expect(type.value).to eq(48)
        end
      end
    end
  end
end
