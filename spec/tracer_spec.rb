# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1 # rubocop:disable Metrics/ModuleLength
  describe Tracer do
    let(:io) { StringIO.new }
    subject(:tracer) { described_class.new(io) }

    it 'puts on given iostream' do
      tracer.trace('test')
      expect(io.string).to eq("test\n")
    end
  end

  describe '.trace' do
    let(:io) { StringIO.new }

    it 'traces a PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new.parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq("INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01\n")
    end

    it 'traces an EXPLICIT PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new(explicit: 8).parse!("\x88\x03\x02\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        EXPLICIT INTEGER id: 8 (0x88), len: 3 (0x03), data: 0x020101
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
      ENDOFTRACE
      )
    end

    it 'traces an IMPLICIT PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new(implicit: 7, class: :application).parse!("\x47\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        IMPLICIT INTEGER id: 7 (0x47), len: 1 (0x01), data: 0x01
      ENDOFTRACE
      )
    end

    it 'traces a ANY parsing' do
      RASN1.trace(io) do
        Types::Any.new.parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq("ANY data: 0x020101\n")
    end

    it 'traces an OPTIONAL ANY parsing' do
      RASN1.trace(io) do
        Types::Any.new(optional: true).parse!('')
        Types::Any.new(optional: true).parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        OPTIONAL ANY NONE
        OPTIONAL ANY data: 0x020101
      ENDOFTRACE
      )
    end

    it 'traces a CONSTRUCTED parsing' do
      seq = Types::Sequence.new(value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
      ENDOFTRACE
      )
    end

    it 'traces an EXPLICIT CONSTRUCTED parsing' do
      seq = Types::Sequence.new(explicit: 4, value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\xa4\x0a\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        EXPLICIT SEQUENCE id: 4 (0xa4), len: 10 (0x0a), data: 0x30080201010403616263
        SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
      ENDOFTRACE
      )
    end

    it 'traces a CONSTRUCTED parsing containing an OPTIONAL element' do
      seq = Types::Sequence.new(value: [Types::Integer.new(optional: true), Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\x30\x05\x04\x03def".b)
        seq.parse!("\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        SEQUENCE id: 16 (0x30), len: 5 (0x05), data: 0x0403646566
        OPTIONAL INTEGER NONE
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x646566
        SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
        OPTIONAL INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
      ENDOFTRACE
      )
    end

    it 'traces a CONSTRUCTED parsing containing an DEFAULT element' do
      seq = Types::Sequence.new(name: 'seq', value: [Types::Integer.new(default: 42), Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\x30\x05\x04\x03def".b)
        seq.parse!("\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~EOD
        seq SEQUENCE id: 16 (0x30), len: 5 (0x05), data: 0x0403646566
        INTEGER DEFAULT VALUE 42
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x646566
        seq SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
        EOD
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
