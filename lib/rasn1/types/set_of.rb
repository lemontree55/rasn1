module RASN1
  module Types
    # ASN.1 SET OF
    # @author Sylvain Daubert
    class SetOf < SequenceOf
      TAG = Set::TAG

      # A SET OF is encoded as a SET.
      # @return ['SET']
      def self.encoded_type
        Set.encoded_type
      end
    end
  end
end
