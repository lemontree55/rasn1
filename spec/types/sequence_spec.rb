# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1
  module Types
    describe Sequence do
      before(:each) do
        @seq = Sequence.new
        @bool = Boolean.new(default: true)
        @int = Integer.new
        @bs = BitString.new
        @seq.value = [@bool, @int, @bs]
        @no_bool_der = "\x30\x09\x02\x01\x2A\x03\x04\x01\x01\x04\x06".b
        @der = "\x30\x0c\x01\x01\x00\x02\x01\x2A\x03\x04\x01\x01\x04\x06".b
      end

      describe '.type' do
        it 'gets ASN.1 type' do
          expect(Sequence.type).to eq('SEQUENCE')
        end
      end

      describe '#initialize' do
        it 'creates an Sequence with default values' do
          seq = Sequence.new
          expect(seq).to be_constructed
          expect(seq).to_not be_optional
          expect(seq.asn1_class).to eq(:universal)
          expect(seq.default).to eq(nil)
        end
      end

      describe '#initialize_copy' do
        it 'deeply copie self' do
          seq = Sequence.new
          rand(10).times do
            seq.value << Integer.new(value: rand(1_000_000))
          end

          seq2 = seq.dup
          expect(seq2).to eq(seq)
          seq.value.size.times do |idx|
            expect(seq2[idx]).to_not eql(seq[idx])
          end
        end
      end

      describe '#to_der' do
        it 'generates a DER string' do
          @int.value = 42
          @bs.value = [1, 4, 6].pack('C3')
          @bs.bit_length = 23
          expect(@seq.to_der).to eq(@no_bool_der)

          @bool.value = false
          expect(@seq.to_der).to eq(@der)
        end

        it 'generates a DER string from a DER-valued SEQUENCE' do
          seq2 = Sequence.new
          seq2.value = @no_bool_der[2, @no_bool_der.length]
          expect(seq2.to_der).to eq(@no_bool_der)
        end

        it 'does not generate a DER string for an optional SEQUENCE which subelement have no value' do
          seq = Sequence.new(optional: true, value: [@bool, @int, @bs])
          expect(seq.to_der).to eq('')
        end
      end

      describe '#parse!' do
        it 'parses DER string' do
          @seq.parse!(@der)
          expect(@bool.value).to be(false)
          expect(@int.value).to eq(42)
          expect(@bs.value).to eq([1, 4, 6].pack('C3'))
          expect(@bs.bit_length).to eq(23)

          @seq.parse!(@no_bool_der)
          expect(@bool.value).to be(true)
          expect(@int.value).to eq(42)
          expect(@bs.value).to eq([1, 4, 6].pack('C3'))
          expect(@bs.bit_length).to eq(23)
        end

        it 'parses a DER string without parsing SEQUENCE content' do
          seq2 = Sequence.new
          seq2.parse!(@der)
          expect(seq2.value).to eq(@der[2, @der.length])
        end
      end

      describe '#inspect' do
        let(:inspect_str) { @seq.inspect }

        it 'prints a line per value' do
          expect(inspect_str.split("\n").size).to eq(4)
        end

        it 'prints optional values' do
          @seq.value[1] = Integer.new(optional: true)
          expect(@seq.inspect.split("\n").size).to eq(4)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
