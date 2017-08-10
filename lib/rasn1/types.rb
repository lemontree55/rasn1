module RASN1
  # This modules is a namesapce for all ASN.1 type classes.
  # @author Sylvain Daubert
  module Types

    # Give all primitive types
    # @return [Array<Types::Primitive>]
    def self.primitives
      self.constants.map { |c| Types.const_get(c) }.
          select { |klass| klass < Primitive }
    end

    # Give all constructed types
    # @return [Array<Types::Constructed>]
    def self.constructed
      self.constants.map { |c| Types.const_get(c) }.
          select { |klass| klass < Constructed }
    end
  end
end

require_relative 'types/base'
require_relative 'types/primitive'
require_relative 'types/boolean'
require_relative 'types/integer'
require_relative 'types/bit_string'
require_relative 'types/octet_string'
require_relative 'types/null'
require_relative 'types/object_id'
require_relative 'types/enumerated'
require_relative 'types/utf8_string'
require_relative 'types/numeric_string'
require_relative 'types/printable_string'
require_relative 'types/ia5string'
require_relative 'types/visible_string'
require_relative 'types/constructed'
require_relative 'types/sequence'
require_relative 'types/sequence_of'
require_relative 'types/set'
require_relative 'types/set_of'
require_relative 'types/choice'
require_relative 'types/any'
