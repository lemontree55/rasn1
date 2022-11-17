# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength,Layout/ClosingParenthesisIndentation
module RASN1 # rubocop:disable Metrics/ModuleLength
  module TestTrace
    DER_SEQUENCE = "\x30\x08\x02\x01\x01\x04\x03abc".b.freeze
    TRACE_SEQUENCE = <<~ENDOFTRACE
      SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
      INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
      OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
    ENDOFTRACE

    DER_EXPLICIT_SEQUENCE = "\xa4\x0a\x30\x08\x02\x01\x01\x04\x03abc".b.freeze
    TRACE_EXPLICIT_SEQUENCE = <<~ENDOFTRACE
      EXPLICIT SEQUENCE id: 4 (0xa4), len: 10 (0x0a), data: 0x30080201010403616263
      SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
      INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
      OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
    ENDOFTRACE
  end

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
        seq.parse!(TestTrace::DER_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_SEQUENCE)
    end

    it 'traces an EXPLICIT CONSTRUCTED parsing' do
      seq = Types::Sequence.new(explicit: 4, value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!(TestTrace::DER_EXPLICIT_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_EXPLICIT_SEQUENCE)
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
      expect(io.string).to eq(<<~ENDOFTRACE
        seq SEQUENCE id: 16 (0x30), len: 5 (0x05), data: 0x0403646566
        INTEGER DEFAULT VALUE 42
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x646566
        seq SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201010403616263
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
      ENDOFTRACE
      )
    end

    it 'traces a CHOICE parsing' do
      choice = Types::Choice.new(value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        choice.parse!("\x02\x01\x01".b)
        choice.parse!("\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        CHOICE
        INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01
        CHOICE
        OCTET STRING id: 4 (0x04), len: 3 (0x03), data: 0x616263
      ENDOFTRACE
      )
    end

    it 'traces MODEL parsing' do
      model = TestModel::OfModel.new
      RASN1.trace(io) do
        model.parse!("\x30\x12\x30\x06\x02\x01\x0f\x80\x01\x02\x30\x08\x02\x01\x10\x81\x03\x02\x01\x03".b)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        seqof SEQUENCE OF id: 16 (0x30), len: 18 (0x12), data: 0x300602010f80010230080201108103...
        record SEQUENCE id: 16 (0x30), len: 6 (0x06), data: 0x02010f800102
        id INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x0f
        room IMPLICIT OPTIONAL INTEGER id: 0 (0x80), len: 1 (0x01), data: 0x02
        house EXPLICIT INTEGER DEFAULT VALUE 0
        record SEQUENCE id: 16 (0x30), len: 8 (0x08), data: 0x0201108103020103
        id INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x10
        room IMPLICIT OPTIONAL INTEGER NONE
        house EXPLICIT INTEGER id: 1 (0x81), len: 3 (0x03), data: 0x020103
        house INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x03
      ENDOFDATA
      )
    end

    it 'traces wrapped MODEL parsing' do
      model = ModelWithImplicitWrapper.new
      RASN1.trace(io) do
        model.parse!("\x30\x0d\xa5\x0b\x02\x01\x10\x80\x01\x07\x81\x03\x02\x01\x03")
      end
      expect(io.string).to eq(<<~ENDOFDATA
        seq SEQUENCE id: 16 (0x30), len: 13 (0x0d), data: 0xa50b0201108001078103020103
        record IMPLICIT SEQUENCE id: 5 (0xa5), len: 11 (0x0b), data: 0x0201108001078103020103
        id INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x10
        room IMPLICIT OPTIONAL INTEGER id: 0 (0x80), len: 1 (0x01), data: 0x07
        house EXPLICIT INTEGER id: 1 (0x81), len: 3 (0x03), data: 0x020103
        house INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x03
      ENDOFDATA
      )
    end

    it 'traces RASN1.parse' do
      RASN1.trace(io) do
        RASN1.parse(TestTrace::DER_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_SEQUENCE)
    end

    it 'traces RASN1.parse (explicit element)' do
      RASN1.trace(io) do
        RASN1.parse(TestTrace::DER_EXPLICIT_SEQUENCE)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        BASE id: 4 (0xa4), len: 10 (0x0a), data: 0x30080201010403616263
      ENDOFDATA
      )
    end

    it 'traces long length' do
      os = Types::OctetString.new(value: 'a' * 256)
      RASN1.trace(io) do
        RASN1.parse(os.to_der)
      end
      expect(io.string).to eq("OCTET STRING id: 4 (0x04), len: 256 (0x820100), data: 0x616161616161616161616161616161...\n")
    end

    it 'traces long id' do
      os = Types::OctetString.new(implicit: 128, value: 'a')
      RASN1.trace(io) do
        RASN1.parse(os.to_der)
      end
      expect(io.string).to eq("BASE id: 128 (0x9f8100), len: 1 (0x01), data: 0x61\n")
    end
  end
end
# rubocop:enable Metrics/BlockLength,Layout/ClosingParenthesisIndentation
