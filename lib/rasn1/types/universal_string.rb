# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 UniversalString
    # @since 0.13.0
    # @author zeroSteiner
    class UniversalString < OctetString
      # UniversalString id value
      ID = 28

      # Get ASN.1 type
      # @return [String]
      def self.type
        'UniversalString'
      end

      private

      def value_to_der
        @value.to_s.dup.encode('UTF-32BE').b
      end

      def der_to_value(der, ber: false)
        super
        @value = der.to_s.dup.force_encoding('UTF-32BE')
      end
    end
  end
end
