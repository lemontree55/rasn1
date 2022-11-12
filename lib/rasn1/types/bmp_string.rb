# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 BmpString
    # @since 0.12.0
    # @author adfoster-r7
    class BmpString < OctetString
      # BmpString id value
      ID = 30

      # Get ASN.1 type
      # @return [String]
      def self.type
        'BmpString'
      end

      private

      def value_to_der
        @value.to_s.dup.encode('UTF-16BE').b
      end

      def der_to_value(der, ber: false)
        super
        @value = der.to_s.dup.force_encoding('UTF-16BE')
      end
    end
  end
end
