require 'spec_helper'

module RASN1

  describe Types do
    describe '.primitives' do
      it 'gives all subclasses of Primitive' do
        expect(Types.primitives).to include(Types::Boolean,
                                            Types::Integer,
                                            Types::BitString,
                                            Types::OctetString,
                                            Types::Null,
                                            Types::ObjectId,
                                            Types::Enumerated,
                                            Types::Utf8String,
                                            Types::NumericString,
                                            Types::PrintableString,
                                            Types::IA5String,
                                            Types::VisibleString)
      end
    end

    describe '.constructed' do
      it 'gives all subclasses of Constructed' do
        expect(Types.constructed).to include(Types::Sequence,
                                             Types::SequenceOf,
                                             Types::Set,
                                             Types::SetOf)
      end
    end
  end
end
