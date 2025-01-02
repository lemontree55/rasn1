# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 UniversalString
    # @since 0.13.0
    # @author zeroSteiner
    class UniversalString < OctetString
      # UniversalString id value
      ID = 28
      # UniversalString encoding
      # @since 0.15.0
      ENCODING = Encoding::UTF_32BE

      # Get ASN.1 type
      # @return [String]
      def self.type
        'UniversalString'
      end
    end
  end
end
