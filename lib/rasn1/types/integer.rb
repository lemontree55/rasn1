module RASN1
  module Types

    # ASN.1 Integer
    # @author Sylvain Daubert
    class Integer < Primitive
      TAG = 0x02

      # @return [Integer]
      def to_i
        @value || @default || 0
      end

      private

      def value_to_der(value=nil)
        v = value || @value
        size = v.bit_length / 8 + (v.bit_length % 8 > 0 ? 1 : 0)
        size = 1 if size == 0
        comp_value = if v > 0
                       # If MSB is 1, increment size to set initial octet
                       # to 0 to amrk it as a positive integer
                       size += 1 if v >> (size * 8 - 1) == 1
                       v
                     else
                       ~(v.abs) + 1
                     end
        ary = []
        size.times { ary << (comp_value & 0xff); comp_value >>= 8 }
        ary.reverse.pack('C*')
      end

      def der_to_value(der, ber: false)
        ary = der.unpack('C*')
        @value = ary.reduce(0) { |len, b| (len << 8) | b }
        if ary[0] & 0x80 == 0x80
          @value = -((~@value & ((1 << @value.bit_length) - 1)) + 1)
        end
      end
    end
  end
end
