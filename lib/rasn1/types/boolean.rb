module Rasn1
  module Types

    # ASN.1 Boolean
    # @author Sylvain Daubert
    class Boolean < Primitive
      TAG = 0x01

      private

      def value_to_der
        [@value ? 0xff : 0x00].pack('C')
      end
    end
  end
end
