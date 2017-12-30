require_relative '../spec_helper'

module RASN1::Types

  describe UtcTime do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(UtcTime.type).to eq('UTCTime')
      end
    end

    describe '#initialize' do
      it 'creates a UtcTime with default values' do
        utc = UtcTime.new
        expect(utc).to be_primitive
        expect(utc).to_not be_optional
        expect(utc.asn1_class).to eq(:universal)
        expect(utc.default).to eq(nil)
        expect(utc.tag).to eq(23)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        utc = UtcTime.new
        utc.value = Time.utc(2017, 12, 30, 16, 30)
        expect(utc.to_der).to eq(binary("\x17\x0d171230163000Z"))
      end
    end

    describe '#parse!' do
      let(:utc) { UtcTime.new }

      it 'parses a DER UTCTime (without second, Zulu)' do
        utc.parse!(binary("\x17\x0b9901010203Z"))
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 2, 3))
      end

      it 'parses a DER UTCTime (with seconds, Zulu)' do
        utc.parse!(binary("\x17\x0d990101020304Z"))
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 2, 3, 4))
      end

      it 'parses a DER UTCTime (without second, local time)' do
        utc.parse!(binary("\x17\x119901010203-0100"))
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 3, 3))
      end

      it 'parses a DER UTCTime (with seconds, local time)' do
        utc.parse!(binary("\x17\x13990101020304+0100"))
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 1, 3, 4))
      end
    end
  end
end
