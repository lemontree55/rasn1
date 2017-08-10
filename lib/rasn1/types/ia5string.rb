module RASN1
  module Types

    # ASN.1 IA5 String
    # @author Sylvain Daubert
    class IA5String < OctetString
      TAG = 22

      # Get ASN.1 type
      # @return [String]
      def self.type
        self.to_s.gsub(/.*::/, '')
      end

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
