module RASN1
  module Types

    # @abstract This class SHOULD be used as base class for all ASN.1 primitive
    #  types.
    # Base class for all ASN.1 constructed types
    # @author Sylvain Daubert
    class Constructed < Base
      # Constructed value
      ASN1_PC = 0x20
    end
  end
end
