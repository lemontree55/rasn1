module RASN1
  module Types

    # ASN.1 Octet String
    #
    # An OCTET STRINT may contain another primtive object:
    #  os = OctetString.new(:os)
    #  int = Integer.new(:int)
    #  int.value = 12
    #  os.value = int
    #  os.to_der   # => DER string with INTEGER in OCTET STRING
    # @author Sylvain Daubert
    class OctetString < Primitive
      TAG = 0x04

      def inspect(level=0)
        str = ''
        str << '  ' * level if level > 0
        str << "#{@name} " unless @name.nil?
        str << "#{type}: #{value.inspect}"
      end

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
