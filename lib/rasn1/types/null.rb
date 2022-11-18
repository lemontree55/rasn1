# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Null
    # @author Sylvain Daubert
    class Null < Primitive
      # Null id value
      ID = 0x05

      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)[0..-2] # remove terminal ':'
        str << ' OPTIONAL' if optional?
        str
      end

      # @return [Boolean]
      # Build only if not optional
      def can_build?
        !optional?
      end

      private

      def value_to_der
        ''
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        raise ASN1Error, 'NULL should not have content!' if der.length.positive?

        @no_value = true
        @value = void_value
      end
    end
  end
end
