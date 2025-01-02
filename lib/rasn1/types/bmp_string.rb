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

      # Make string value from DER/BER string. Force encoding to UTF-16BE.
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @see Types::Base#der_to_value
      def der_to_value(der, ber: false)
        super
        @value = der.to_s.dup.force_encoding('UTF-16BE')
      end

      private

      def value_to_der
        @value.to_s.dup.encode('UTF-16BE').b
      end
    end
  end
end
