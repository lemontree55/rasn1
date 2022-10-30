# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Printable String
    # @author Sylvain Daubert
    class PrintableString < OctetString
      # PrintableString id value
      ID = 19

      # Get ASN.1 type
      # @return [String]
      def self.type
        'PrintableString'
      end

      private

      def value_to_der
        check_characters
        @value.to_s.b
      end

      def der_to_value(der, ber: false)
        super
        check_characters
      end

      def check_characters
        m = @value.to_s.match(%r{([^a-zA-Z0-9 '=()+,\-./:?])})
        raise ASN1Error, "PRINTABLE STRING #{@name}: invalid character: '#{m[1]}'" if m
      end
    end
  end
end
