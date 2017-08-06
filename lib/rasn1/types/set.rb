module RASN1
  module Types

    # ASN.1 set
    #
    # A set is a collection of another ASN.1 types.
    #
    # To encode this ASN.1 example:
    #  Record ::= SET {
    #    id        INTEGER,
    #    room  [0] INTEGER OPTIONAL,
    #    house [1] IMPLICIT INTEGER DEFAULT 0
    #  }
    # do:
    #  set = RASN1::Types::Set.new(:record)
    #  set.value = [
    #               RASN1::Types::Integer(:id),
    #               RASN1::Types::Integer(:id, explicit: 0, optional: true),
    #               RASN1::Types::Integer(:id, implicit: 1, default: 0)
    #              ]
    # @author Sylvain Daubert
    class Set < Sequence
      TAG = 0x11
    end
  end
end
