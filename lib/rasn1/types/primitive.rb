# frozen_string_literal: true

module RASN1
  module Types
    # @abstract This class SHOULD be used as base class for all ASN.1 primitive
    #  types.
    # @author Sylvain Daubert
    class Primitive < Base
      # Primitive value
      ASN1_PC = 0x00
    end
  end
end
