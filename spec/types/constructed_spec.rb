require_relative '../spec_helper'

module RASN1::Types
  describe Constructed do
    it 'has a PC bit set' do
      expect(Sequence.new.tag & Constructed::ASN1_PC).to eq(Constructed::ASN1_PC)
    end

    describe '#inspect' do
      it 'handles Array-value types' do
        seq = Sequence.new
        expect(seq.inspect).to eq("SEQUENCE:\n")
        bool= Boolean.new(value: true)
        int =  Integer.new(value: 1)
        seq.value = [bool, int]
        expect(seq.inspect).to eq("SEQUENCE:\n  #{bool.inspect}\n  #{int.inspect}\n")
      end

      it 'handles name' do
        seq = Sequence.new(name: :seq)
        expect(seq.inspect).to eq("seq SEQUENCE:\n")
        bool= Boolean.new(name: :bool, value: true)
        seq.value = [bool]
        expect(seq.inspect).to eq("seq SEQUENCE:\n  #{bool.inspect}\n")
      end

      it 'handles foreign elements' do
        seq = Sequence.new
        bs = BitString.new(value: 'abcd', bit_length: 23)
        seq.value = [bs.to_der]
        expect(seq.inspect).to eq("SEQUENCE:\n  #{bs.to_der.inspect}\n")
      end
    end
  end
end
