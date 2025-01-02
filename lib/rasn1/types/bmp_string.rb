# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 BmpString
    # @since 0.12.0
    # @author adfoster-r7
    class BmpString < OctetString
      # BmpString id value
      ID = 30
      # UniversalString encoding
      # @since 0.15.0
      ENCODING = Encoding::UTF_16BE

      # Get ASN.1 type
      # @return [String]
      def self.type
        'BmpString'
      end
    end
  end
end
