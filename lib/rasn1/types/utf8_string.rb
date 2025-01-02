# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 UTF8 String
    # @author Sylvain Daubert
    class Utf8String < OctetString
      # Utf8String id value
      ID = 12
      # Utf8String encoding
      # @since 0.15.0
      ENCODING = Encoding::UTF_8

      # Get ASN.1 type
      # @return [String]
      def self.type
        'UTF8String'
      end
    end
  end
end
