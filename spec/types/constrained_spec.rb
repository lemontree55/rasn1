# frozen_string_literal: true

require_relative '../spec_helper'

module RASN1Test::Constrained
  RASN1::Types.define_type('UInt32', from: RASN1::Types::Integer, in_module: self) do |val|
    (val >= 0) && (val < (2**32))
  end
  RASN1::Types.define_type('Int', from: RASN1::Types::Integer, in_module: self)
  RASN1::Types.define_type('MySeq', from: RASN1::Types::Sequence, in_module: self)

  RASN1::Types.define_type('Int32', from: RASN1::Types::Integer, in_module: self) do |value|
    (value >= -2**31) && (value < 2**31)
  end
  RASN1::Types.define_type('LocalSeq', from: RASN1::Types::Sequence, in_module: self)

  class MyDefinedModel < RASN1::Model
    local_seq :myseq, content: [
      int32(:id),
      integer(:normal_integer)
    ]
  end
end

# rubocop:disable Metrics/BlockLength
module RASN1::Types
  describe Constrained do
    describe '.constrained?' do
      it 'returns true for contrained type' do
        expect(RASN1Test::Constrained::UInt32.constrained?).to be(true)
      end
      it 'returns false for uncontrained type' do
        expect(RASN1Test::Constrained::Int.constrained?).to be(false)
      end

      it 'returns false for a predefined type' do
        expect(Integer.constrained?).to be(false)
      end
    end

    describe '#value=' do
      context '(constrained type)' do
        let(:uint32) { RASN1Test::Constrained::UInt32.new }

        it 'accepts a value in constraint' do
          expect { uint32.value = 2**32 - 1 }.not_to raise_error
          expect(uint32.value).to eq(2**32 - 1)
        end

        it 'raises with a value out of constraint' do
          expect { uint32.value = -1 }.to raise_error(RASN1::ConstraintError)
        end
      end

      context '(unconstrained type)' do
        let(:int) { RASN1Test::Constrained::Int.new }

        it 'accepts all values' do
          [-1, 0, 1, 2**32 - 1, 2**32].each do |val|
            expect { int.value = val }.to_not raise_error
          end
        end
      end
    end

    describe '#parse!' do
      let(:der_one) { "\x02\x01\x00" }
      let(:der_pow32_minus1) { "\x02\x05\x00\xff\xff\xff\xff" }
      let(:der_minus1) { "\x02\x01\xff" }

      context '(constrained type)' do
        let(:uint32) { RASN1Test::Constrained::UInt32.new }

        it 'parse a DER whose value is in constraint' do
          expect { uint32.parse!(der_one) }.to_not raise_error
          expect(uint32.value).to eq(0)

          expect { uint32.parse!(der_pow32_minus1) }.to_not raise_error
          expect(uint32.value).to eq(2**32 - 1)
        end

        it 'raises on DER whose value is out of constraint' do
          expect { uint32.parse!(der_minus1) }.to raise_error(RASN1::ConstraintError)
        end
      end

      context '(unconstrained type)' do
        let(:int) { RASN1Test::Constrained::Int.new }

        it 'parses all values' do
          [der_one, der_pow32_minus1, der_minus1].each do |der|
            expect { int.parse!(der) }.to_not raise_error
          end
        end
      end
    end
  end
end

module RASN1
  describe Model do
    it 'gives access to defined type fields' do
      mdm = RASN1Test::Constrained::MyDefinedModel.new(id: 123, normal_integer: 124)
      expect(mdm[:id]).to be_a(RASN1Test::Constrained::Int32)
      expect(mdm[:id].value).to eq(123)
      expect(mdm[:normal_integer].value).to eq(124)
    end
  end
end
# rubocop:enable Metrics/BlockLength
