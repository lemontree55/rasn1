# frozen_string_literal: true

require_relative 'rasn1/version'
require_relative 'rasn1/errors'
require_relative 'rasn1/types'
require_relative 'rasn1/model'
require_relative 'rasn1/wrapper'

# Rasn1 is a pure ruby library to parse, decode and encode ASN.1 data.
# @author Sylvain Daubert
module RASN1
  # Parse a DER/BER string without checking a model
  # @note If you want to check ASN.1 grammary, you should define a {Model}
  #       and use {Model#parse}.
  # @note This method will never decode SEQUENCE OF or SET OF objects, as these
  #       ones use the same encoding as SEQUENCE and SET, respectively.
  # @note Real type of tagged value cannot be guessed. So, such tag will
  #       generate {Types::Base} objects.
  # @param [String] der binary string to parse
  # @param [Boolean] ber if +true+, decode a BER string, else a DER one
  # @return [Types::Base]
  def self.parse(der, ber: false)
    root = nil
    until der.empty?
      type = Types.id2type(der)
      type.parse!(der, ber: ber)
      root ||= type

      if [Types::Sequence, Types::Set].include? type.class
        subder = type.value
        ary = []
        until subder.empty?
          ary << self.parse(subder)
          subder = subder[ary.last.to_der.size..-1]
        end
        type.value = ary
      end
      der = der[type.to_der.size..-1]
    end
    root
  end
end
