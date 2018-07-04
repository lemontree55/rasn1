module RASN1
  module Types

    # ASN.1 Null
    # @author Sylvain Daubert
    class Null < Primitive
      TAG = 0x05

      # @return [String]
      def inspect(level=0)
        str = ''
        str << '  ' * level if level > 0
        str << "#{@name} " unless @name.nil?
        str << "#{type}"
        str << " OPTIONAL" if optional?
        str
      end

      private

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
