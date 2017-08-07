module RASN1
  module Types

    # ASN.1 UTF8 String
    # @author Sylvain Daubert
    class Utf8String < OctetString
      TAG = 12

      private
      
      def value_to_der
        @value.to_s.force_encoding('UTF-8').force_encoding('BINARY')
      end

      def der_to_value(der, ber:false)
        @value = der.force_encoding('UTF-8')
      end
    end
  end
end