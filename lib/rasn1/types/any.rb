# frozen_string_literal: true

module RASN1
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
        total_length, _data = do_parse(der, ber)
        total_length
      end

      # @param [::Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << if !value?
                 'NULL'
               elsif @value.is_a?(OctetString) || @value.is_a?(BitString)
                 "#{@value.type}: #{value.value.inspect}"
               elsif @value.class < Base
                 "#{@value.type}: #{value.value}"
               else
                 value.to_s.inspect
               end
      end

      # @private Tracer private API
      # @return [String]
      def trace
        return trace_any if value?

        msg_type(no_id: true) << ' NONE'
      end

      private

      def common_inspect(level)
        lvl = level >= 0 ? level : 0
        str = '  ' * lvl
        str << "#{@name} " unless @name.nil?
        str << asn1_class.to_s.upcase << ' ' unless asn1_class == :universal
        str << "[#{id}] EXPLICIT " if explicit?
        str << "[#{id}] IMPLICIT " if implicit?
        str << '(ANY) '
      end

      def do_parse(der, ber)
        if der.empty?
          return [0, ''] if optional?

          raise ASN1Error, 'Expected ANY but get nothing'
        end

        id_size = Types.decode_identifier_octets(der).last
        total_length, = get_data(der[id_size..-1], ber)
        total_length += id_size

        @no_value = false
        @value = der[0, total_length]

        [total_length, @value]
      end

      def trace_any
        msg_type(no_id: true) << trace_data(value)
      end
    end
  end
end
