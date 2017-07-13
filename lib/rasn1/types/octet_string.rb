module RASN1
  module Types

    # ASN.1 Octet String
    # @author Sylvain Daubert
    class OctetString < Primitive
      TAG = 0x04

      private

      def value_to_der
        case @value
        when Base
          @value.to_der
        else
          @value.to_s
        end
      end

      def der_to_value(der, ber:false)
        @value = der
      end
    end
  end
end

