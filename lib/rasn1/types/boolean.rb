# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Boolean
    # @author Sylvain Daubert
    class Boolean < Primitive
      # Boolean id value
      ID = 0x01

      # @private
      DER_TRUE = 0xff
      # @private
      DER_FALSE = 0

      # @return [false]
      def void_value
        false
      end

      private

      def value_to_der
        [@value ? DER_TRUE : DER_FALSE].pack('C')
      end

      def der_to_value(der, ber: false)
        raise ASN1Error, "tag #{@name}: BOOLEAN should have a length of 1" unless der.size == 1

        bool = der.unpack1('C')
        case bool
        when DER_FALSE
          @value = false
        when DER_TRUE
          @value = true
        else
          raise ASN1Error, "tag #{@name}: bad value 0x%02x for BOOLEAN" % bool unless ber

          @value = true
        end
      end

      def trace_data
        return super if explicit?

        "    #{raw_data == "\x00".b ? 'FALSE' : 'TRUE'} (0x#{raw_data.unpack1('H*')})"
      end
    end
  end
end
