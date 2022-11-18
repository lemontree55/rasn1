# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Octet String
    #
    # An OCTET STRINT may contain another primtive object:
    #  os = OctetString.new
    #  int = Integer.new
    #  int.value = 12
    #  os.value = int
    #  os.to_der   # => DER string with INTEGER in OCTET STRING
    # @author Sylvain Daubert
    class OctetString < Primitive
      # OctetString id value
      ID = 4

      # @param [::Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << " #{value.inspect}"
      end
    end
  end
end
