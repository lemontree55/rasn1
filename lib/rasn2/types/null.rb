# frozen_string_literal: true

module RASN2
  module Types
    # ASN.1 Null
    # @author Sylvain Daubert
    class Null < Primitive
      # Null id value
      ID = 0x05

      # @return [String]
      def inspect(level=0, color: true)
        begin_colorizer(color)
        result = common_inspect(level)
        end_colorizer
        result
      end

      # @return [Boolean]
      # Build only if not optional
      def can_build?
        !optional?
      end

      # Check +der+ string
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @raise [ASN1Error] +der+ is not empty
      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        raise ASN1Error, 'NULL should not have content!' if der.length.positive?

        @no_value = true
        @value = void_value
      end

      private

      def value_to_der
        ''
      end
    end
  end
end
