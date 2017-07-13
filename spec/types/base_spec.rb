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
      let(:unexpected_der) { "\x02\x02\xca\xfe".force_encoding('BINARY') }

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

      it 'raises on indefinite length with primitive types' do
        bool = Boolean.new(:bool)
        der = "\x01\x80\xff\x00\x00".force_encoding('BINARY')
        expect { bool.parse!(der) }.to raise_error(RASN1::ASN1Error).
          with_message('malformed BOOLEAN TAG (bool): indefinite length forbidden for primitive types')
      end

      it 'raises on indefinite length with constructed types on DER encoding'
      it 'raises on indefinite length with constructed types on BER encoding'
    end
  end
end
