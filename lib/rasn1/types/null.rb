module RASN1
  module Types

    # ASN.1 Null
    # @author Sylvain Daubert
    class Null < Primitive
      TAG = 0x05

      def value_to_der
        ''
      end

      def der_to_value(der, ber: false)
        raise ASN1Error, "NULL TAG should not have content!" if der.length > 0
        @value = nil
      end
    end
  end
end
