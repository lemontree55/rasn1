# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
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
        expect(utc.id).to eq(23)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        utc = UtcTime.new
        utc.value = Time.utc(2017, 12, 30, 16, 30)
        expect(utc.to_der).to eq("\x17\x0d171230163000Z".b)
      end
    end

    describe '#parse!' do
      let(:utc) { UtcTime.new }

      it 'parses a DER UTCTime (without second, Zulu)' do
        utc.parse!("\x17\x0b9901010203Z".b)
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 2, 3))
      end

      it 'parses a DER UTCTime (with seconds, Zulu)' do
        utc.parse!("\x17\x0d990101020304Z".b)
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 2, 3, 4))
      end

      it 'parses a DER UTCTime (without second, local time)' do
        utc.parse!("\x17\x119901010203-0100".b)
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 3, 3))
      end

      it 'parses a DER UTCTime (with seconds, local time)' do
        utc.parse!("\x17\x13990101020304+0100".b)
        expect(utc.value).to eq(Time.utc(2099, 1, 1, 1, 3, 4))
      end

      it 'raises ASN1Error on unknown format' do
        expect { utc.parse!("\x17\x05aaaaa") }.to raise_error(RASN1::ASN1Error).with_message(/unrecognized format/)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
