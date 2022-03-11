require_relative '../spec_helper'

module RASN1
  module Types
    describe SetOf do
      it '.type gets ASN.1 type' do
        expect(SetOf.type).to eq('SET OF')
      end

      it '.encoded_type returns same type as Set' do
        expect(SetOf.encoded_type).to eq('SET')
      end
    end
  end
end