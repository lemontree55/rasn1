require_relative '../spec_helper'

module RASN1::Types

  describe Base do

    describe '#initialize' do
      it 'sets name' do
        base = Base.new('my_name')
        expect(base.name).to eq('my_name')
        expect(base.optional?).to be(false)
        expect(base.default).to be(nil)
        expect(base.value).to be(nil)
      end

      it 'accepts options' do
        expect { Base.new(:name, opt1: 1, opt2: 2) }.to_not raise_error
      end

      it 'sets class option' do
        Base::CLASSES.keys.each do |asn1_class|
          base = Base.new(:name, class: asn1_class)
          expect(base.asn1_class).to eq(asn1_class)
        end
      end

      it 'raises on unknown class' do
        expect { Base.new(:name, class: :unknown) }.to raise_error(RASN1::ClassError)
        expect { Base.new(:name, class: 'not a symbol') }.to raise_error(RASN1::ClassError)
      end

      it 'sets optional option' do
        base = Base.new(:name, optional: true)
        expect(base.optional?).to be(true)
        base = Base.new(:name, optional: 12)
        expect(base.optional?).to be(true)
        base = Base.new(:name, optional: nil)
        expect(base.optional?).to be(false)
      end

      it 'sets default option' do
        base = Base.new(:name, default: '123')
        expect(base.default).to eq('123')
      end
    end

    describe '#to_der' do
      it 'raises NotImplementedError' do
        expect { Base.new(:name).to_der }.to raise_error(NotImplementedError)
      end
    end

    describe '#primitive?' do
      it 'returns false' do
        expect(Base.new(:name).primitive?).to be(false)
      end
    end
    
    describe '#constructed?' do
      it 'returns false' do
        expect(Base.new(:name).constructed?).to be(false)
      end
    end

    describe '#parse!' do
      let(:unexpected_der) { binary("\x02\x02\xca\xfe") }

      it 'raises on unexpected tag value' do
        bool = Boolean.new(:bool)
        expect { bool.parse!(unexpected_der) }.to raise_error(RASN1::ASN1Error).
          with_message('Expected tag UNIVERSAL PRIMITIVE BOOLEAN but get UNIVERSAL PRIMITIVE INTEGER for bool')
      end

      it 'does not raise on unexpected tag value with OPTIONAL tag' do
        bool = Boolean.new(:bool, optional: true)
        expect { bool.parse!(unexpected_der) }.to_not raise_error
        expect(bool.value).to be(nil)
      end

      it 'does not raise on unexpected tag value with DEFAULT tag' do
        bool = Boolean.new(:bool, default: false)
        expect { bool.parse!(unexpected_der) }.to_not raise_error
      end

      it 'sets value to default one when parsing an unexpected tag with DEFAULT one' do
        bool = Boolean.new(:bool, default: false)
        bool.parse!(unexpected_der)
        expect(bool.value).to be(false)
      end

      it 'parses tags with multi-byte length' do
        bs = BitString.new(:bs)

        der = "\x03\x82\x01\x03\x00" + 'a' * 0x102
        expect(bs.parse!(der)).to eq(0x107)
        expect(bs.value).to eq('a' * 0x102)
        expect(bs.bit_length).to eq(0x102 * 8)
      end

      it 'returns total number of parsed bytes' do
        int = Integer.new(:int)
        bytes = int.parse!(binary("\x02\x01\x01"))
        expect(bytes).to eq(3)
        expect(int.value).to eq(1)
        bytes = int.parse!(binary("\x02\x01\x01\x02"))
        expect(bytes).to eq(3)
        expect(int.value).to eq(1)
      end

      it 'raises on indefinite length with primitive types' do
        bool = Boolean.new(:bool)
        der = binary("\x01\x80\xff\x00\x00")
        expect { bool.parse!(der) }.to raise_error(RASN1::ASN1Error).
          with_message('malformed BOOLEAN TAG (bool): indefinite length forbidden for primitive types')
      end

      context 'raises on indefinite length with constructed types' do
        let(:der) { binary("\x30\x80\x01\x01\xFF\x00\x00") }
        let(:seq) { seq = Sequence.new(:seq); seq.value = [Boolean.new(:bool)]; seq }

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
          type = Integer.new(:explicit_type, explicit: 5)
          expect(type.tagged?).to be(true)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:context)
          expect(type.tag).to eq(0x85)
        end

        it 'creates an explicit application tagged type' do
          type = Integer.new(:explicit_type, explicit: 0, class: :application)
          expect(type.tagged?).to be(true)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:application)
          expect(type.tag).to eq(0x40)
        end

        it 'creates an explicit private tagged type' do
          type = Integer.new(:explicit_type, explicit: 15, class: :private)
          expect(type.tagged?).to be(true)
          expect(type.explicit?).to be(true)
          expect(type.asn1_class).to eq(:private)
          expect(type.tag).to eq(0xcf)
        end

        it 'creates an implicit tagged type' do
          type = Integer.new(:implicit_type, implicit: 5)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:context)
          expect(type.tag).to eq(0x85)
        end

        it 'creates an implicit application tagged type' do
          type = Integer.new(:implicit_type, implicit: 0, class: :application)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:application)
          expect(type.tag).to eq(0x40)
        end

        it 'creates an implicit private tagged type' do
          type = Integer.new(:implicit_type, implicit: 15, class: :private)
          expect(type.tagged?).to be(true)
          expect(type.implicit?).to be(true)
          expect(type.asn1_class).to eq(:private)
          expect(type.tag).to eq(0xcf)
        end
      end

      describe '#to_der' do
        it 'creates a DER string with explicit tagged type' do
          type = Integer.new(:explicit_type, explicit: 5)
          type.value = 48
          expect(type.to_der).to eq(binary("\x85\x03\x02\x01\x30"))
        end

        it 'creates a DER string with implicit tagged type' do
          type = Integer.new(:explicit_type, implicit: 5)
          type.value = 48
          expect(type.to_der).to eq(binary("\x85\x01\x30"))
        end
      end

      describe '#parse!' do
        it 'parses a DER string with explicit tagged type' do
          type = Integer.new(:explicit_type, explicit: 5)
          type.parse!(binary("\x85\x03\x02\x01\x30"))
          expect(type.value).to eq(48)
        end

        it 'parses a DER string with implicit tagged type' do
          type = Integer.new(:implicit_type, implicit: 5)
          type.parse!(binary("\x85\x01\x30"))
          expect(type.value).to eq(48)
        end
      end
    end
  end
end
