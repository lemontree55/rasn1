require 'spec_helper'

module RASN1

  describe Types do
    describe '.primitives' do
      it 'gives all subclasses of Primitive' do
        expect(Types.primitives).to eq([Types::Boolean,
                                        Types::Integer,
                                        Types::BitString,
                                        Types::OctetString,
                                        Types::Null,
                                        Types::Enumerated])
      end
    end

    describe '.constructed' do
      it 'gives all subclasses of Constructed' do
        expect(Types.constructed).to eq([Types::Sequence])
      end
    end
  end
end
