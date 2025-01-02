# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 IA5 String
    # @author Sylvain Daubert
    class IA5String < OctetString
      # IA5String id value
      ID = 22
      # UniversalString encoding
      # @since 0.15.0
      ENCODING = Encoding::US_ASCII

      # Get ASN.1 type
      # @return [String]
      def self.type
        'IA5String'
      end
    end
  end
end
