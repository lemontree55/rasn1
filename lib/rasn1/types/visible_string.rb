module RASN1
  module Types

    # ASN.1 Visible String
    # @author Sylvain Daubert
    class VisibleString < OctetString
      TAG = 26

      private
      
      def value_to_der
        @value.to_s.force_encoding('US-ASCII').force_encoding('BINARY')
      end

      def der_to_value(der, ber:false)
        super
        @value.force_encoding('US-ASCII')
      end
    end
  end
end
