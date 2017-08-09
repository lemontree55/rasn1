module RASN1
  module Types

    # ASN.1 Printable String
    # @author Sylvain Daubert
    class PrintableString < OctetString
      TAG = 19

      private
      
      def value_to_der
        check_characters
        @value.to_s.force_encoding('BINARY')
      end

      def der_to_value(der, ber:false)
        super
        check_characters
      end

      def check_characters
        if @value.to_s =~ /([^a-zA-Z0-9 '=\(\)\+,\-\.\/:\?])/
          raise ASN1Error, "PRINTABLE STRIN G #@name: invalid character: '#{$1}'"
        end
      end
    end
  end
end
