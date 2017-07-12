module Rasn1
  module Types

    # Base class for all ASN.1 constructed types
    # @author Sylvain Daubert
    class Constructed < Base
      # Constructed value
      ASN1_PC = 0x20
    end
  end
end
