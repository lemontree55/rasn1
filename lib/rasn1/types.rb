module RASN1
  # This modules is a namesapce for all ASN.1 type classes.
  # @author Sylvain Daubert
  module Types

    # Give all primitive types
    # @return [Array<Types::Primitive>]
    def self.primitives
      @primitives ||= self.constants.map { |c| Types.const_get(c) }.
                           select { |klass| klass < Primitive }
    end

    # Give all constructed types
    # @return [Array<Types::Constructed>]
    def self.constructed
      @constructed ||= self.constants.map { |c| Types.const_get(c) }.
                            select { |klass| klass < Constructed }
    end

    # Give ASN.1 type from an integer. If +tag+ is unknown, return a {Types::Base}
    # object.
    # @param [Integer] tag
    # @return [Types::Base]
    # @raise [ASN1Error] +tag+ is out of range
    def self.tag2type(tag)
      raise ASN1Error, "tag is out of range" if tag > 0xff

      if !defined? @tag2types
        constructed = self.constructed - [Types::SequenceOf, Types::SetOf]
        primitives = self.primitives - [Types::Enumerated]
        ary = [primitives, constructed].flatten.map do |type|
          next unless type.const_defined? :TAG
          [type::TAG, type]
        end
        @tag2types = Hash[ary]
        @tag2types.default = Types::Base
      end

      klass = @tag2types[tag & 0xdf] # Remove CONSTRUCTED bit
      is_constructed = (tag & 0x20) == 0x20
      asn1class = Types::Base::CLASSES.key(tag & 0xc0)
      options = { class: asn1class, constructed: is_constructed }
      options[:tag_value] = (tag & 0x1f) if klass == Types::Base
      klass.new(options)
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
require_relative 'types/utc_time'
