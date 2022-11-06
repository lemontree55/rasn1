# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1::Types
  describe GeneralizedTime do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(GeneralizedTime.type).to eq('GeneralizedTime')
      end
    end

    describe '#initialize' do
      it 'creates a GeneralizedTime with default values' do
        utc = GeneralizedTime.new
        expect(utc).to be_primitive
        expect(utc).to_not be_optional
        expect(utc.asn1_class).to eq(:universal)
        expect(utc.default).to eq(nil)
        expect(utc.id).to eq(24)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        gt = GeneralizedTime.new
        gt.value = DateTime.new(2017, 12, 30, 16, 30, 0, 0)
        expect(gt.to_der).to eq("\x18\x0f20171230163000Z".b)
      end

      it 'generates a DER string with fragments of a second' do
        gt = GeneralizedTime.new
        gt.value = DateTime.new(2017, 12, 30, 16, 30, 23.55, 0)
        expect(gt.to_der).to eq("\x18\x1220171230163023.55Z".b)
      end

      it 'generates a DER string with a Time object' do
        gt = GeneralizedTime.new
        gt.value = Time.new(2017, 12, 30, 16, 30, 23.55, 0)
        expect(gt.to_der).to eq("\x18\x1220171230163023.55Z".b)
      end
    end

    describe '#parse!' do
      let(:gt) { GeneralizedTime.new }

      it 'parses a DER GeneralizedTime (UTC, hours only)' do
        gt.parse!("\x18\x0b2017123012Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 0, 0, 0))
        gt.parse!("\x18\x0e2017123012.25Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 15, 0, 0))
        gt.parse!("\x18\x102017123012.2503Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 15, 1.08, 0))
      end

      it 'parses a DER GeneralizedTime (UTC, hours and minutes only)' do
        gt.parse!("\x18\x0d201712301233Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 33, 0, 0))
        gt.parse!("\x18\x0f201712301233.2Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 33, 12, 0))
      end

      it 'parses a DER GeneralizedTime (UTC, hours, minutes and seconds)' do
        gt.parse!("\x18\x0f20171230123426Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 34, 26, 0))
        gt.parse!("\x18\x1420171230123426.0001Z")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 34, 26.0001, 0))
      end

      it 'parses a DER GeneralizedTime (local time, hours only)' do
        gt.parse!("\x18\x0a2017123012")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12).to_datetime)
        gt.parse!("\x18\x0d2017123012.25")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12, 15).to_datetime)
        gt.parse!("\x18\x0f2017123012.2503")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12, 15, 1, 80_000).to_datetime)
      end

      it 'parses a DER GeneralizedTime (local time, hours and minutes only)' do
        gt.parse!("\x18\x0c201712301233")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12, 33).to_datetime)
        gt.parse!("\x18\x0e201712301233.4")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12, 33, 24).to_datetime)
      end

      it 'parses a DER GeneralizedTime (local time, hours, minutes and seconds)' do
        gt.parse!("\x18\x0e20171230123326")
        expect(gt.value).to eq(Time.local(2017, 12, 30, 12, 33, 26).to_datetime)
        gt.parse!("\x18\x1120171230123326.05")
        expect(gt.value).to eq((Time.local(2017, 12, 30, 12, 33, 26) + 5/100r).to_datetime)
      end

      it 'parses a DER GeneralizedTime (local time with difference with UTC, hours only)' do
        gt.parse!("\x18\x0f2017123012+0200")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 0, 0, '+2'))
        gt.parse!("\x18\x112017123012.5+0200")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 30, 0, '+2'))
        gt.parse!("\x18\x142017123012.2503+0200")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 15, 1.08, '+2'))
      end

      it 'parses a DER GeneralizedTime (local time with difference with UTC, hours and minutes only)' do
        gt.parse!("\x18\x11201712301256+0200")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 10, 56, 0, 0))
        gt.parse!("\x18\x13201712301256.1+0200")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 10, 56, 6, 0))
      end

      it 'parses a DER GeneralizedTime (local time with difference with UTC, hours, minutes and seconds)' do
        gt.parse!("\x18\x1320171230125645-1000")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 56, 45, '-10'))
        gt.parse!("\x18\x1720171230125645.123-0400")
        expect(gt.value).to eq(DateTime.new(2017, 12, 30, 12, 56, 45 + 123/1000r, '-4'))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
