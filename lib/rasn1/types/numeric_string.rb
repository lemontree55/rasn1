# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Numeric String
    # @author Sylvain Daubert
    class NumericString < OctetString
      # NumericString id value
      ID = 18
      # Invalid characters in NumericString
      INVALID_CHARS = /([^0-9 ])/

      # Get ASN.1 type
      # @return [String]
      def self.type
        'NumericString'
      end

      # Make string value from +der+ string
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @raise [ASN1Error] invalid characters detected
      def der_to_value(der, ber: false)
        super
        check_characters
      end

      private

      def value_to_der
        check_characters
        @value.to_s.b
      end

      def check_characters
        raise ASN1Error, "NUMERIC STRING #{@name}: invalid character: '#{$1}'" if @value.to_s =~ INVALID_CHARS
      end
    end
  end
end
