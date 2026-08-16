# frozen_string_literal: true

module RASN2
  module Types
    # ASN.1 ANY: accepts any types
    #
    # If `any#value` is `nil` and Any object is not {#optional?}, `any` will be encoded as a {Null} object.
    # @author Sylvain Daubert
    class Any < Base
      # @return [String] DER-formated string
      def to_der
        if value?
          case @value
          when Base, Model
            @value.to_der
          else
            @value.to_s
          end
        else
          optional? ? '' : Null.new.to_der
        end
      end

      def can_build?
        value? || !optional?
      end

      # Parse a DER string. This method updates object: {#value} will be a DER
      # string.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      def parse!(der, ber: false)
        total_length, data = do_parse(der, ber: ber)
        @value = data
        total_length
      end

      # @private Tracer private API
      # @return [String]
      def trace
        return trace_any if value?

        parts = []
        parts << msg_type(no_id: true)
        parts << colorize_nil
        parts.reject(&:empty?).join(' ')
      end

      # @private
      # @see Types::Base#do_parse
      def do_parse(der, ber: false)
        asn1_class, _pc, id, id_size = Types.decode_identifier_octets(der)
        @id = id
        @asn1_class = asn1_class

        if der.empty?
          return [0, ''] if optional?

          raise ASN1Error, 'Expected ANY but get nothing'
        end

        total_length, = get_data(der[id_size..], ber)
        total_length += id_size

        @no_value = false
        real_value = der[0, total_length].to_s
        @value = if constructed?
                   RASN2.parse(real_value, ber: ber)
                 else
                   real_value
                 end

        [total_length, @value]
      end

      def trace_any
        "#{msg_type(no_id: false)}#{trace_data(value)}"
      end
    end
  end
end
