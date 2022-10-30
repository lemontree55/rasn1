require_relative '../spec_helper'

module RASN1
  module Types

    describe Set do
        before(:each) do
          @set = Set.new
          @bool = Boolean.new(default: true)
          @int = Integer.new
          @bs = BitString.new
          @set.value = [@bool, @int, @bs]

          @no_bool_der = "\x31\x09\x02\x01\x2A\x03\x04\x01\x01\x04\x06".b
          @der = "\x31\x0c\x01\x01\x00\x02\x01\x2A\x03\x04\x01\x01\x04\x06".b
        end

      describe '.type' do
        it 'gets ASN.1 type' do
          expect(Set.type).to eq('SET')
        end
      end

      describe '#initialize' do
        it 'creates an Set with default values' do
          set = Set.new
          expect(set).to be_constructed
          expect(set).to_not be_optional
          expect(set.asn1_class).to eq(:universal)
          expect(set.default).to eq(nil)
        end
      end

      describe '#to_der' do
        it 'generates a DER string' do
          @int.value = 42
          @bs.value = [1,4,6].pack('C3')
          @bs.bit_length = 23
          expect(@set.to_der).to eq(@no_bool_der)

          @bool.value = false
          expect(@set.to_der).to eq(@der)
        end
      end

      describe '#parse!' do
        it 'parses DER string' do
          @set.parse!(@der)
          expect(@bool.value).to be(false)
          expect(@int.value).to eq(42)
          expect(@bs.value).to eq([1,4,6].pack('C3'))
          expect(@bs.bit_length).to eq(23)

          @set.parse!(@no_bool_der)
          expect(@bool.value).to be(true)
          expect(@int.value).to eq(42)
          expect(@bs.value).to eq([1,4,6].pack('C3'))
          expect(@bs.bit_length).to eq(23)
        end
      end
    end
  end
end
