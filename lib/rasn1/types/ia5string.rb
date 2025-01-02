# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 IA5 String
    # @author Sylvain Daubert
    class IA5String < OctetString
      # IA5String id value
      ID = 22

      # Get ASN.1 type
      # @return [String]
      def self.type
        'IA5String'
      end

      # Make string value from +der+ string. Force encoding to +US-ASCII+.
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      def der_to_value(der, ber: false)
        super
        @value.to_s.dup.force_encoding('US-ASCII')
      end

      private

      def value_to_der
        @value.to_s.dup.force_encoding('US-ASCII').b
      end
    end
  end
end
