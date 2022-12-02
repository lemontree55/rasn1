# frozen_string_literal: true

require_relative 'rasn1/version'
require_relative 'rasn1/errors'
require_relative 'rasn1/types'
require_relative 'rasn1/model'
require_relative 'rasn1/wrapper'
require_relative 'rasn1/tracer'

# Rasn1 is a pure ruby library to parse, decode and encode ASN.1 data.
# @author Sylvain Daubert
module RASN1
  # @private
  CONTAINER_CLASSES = [Types::Sequence, Types::Set].freeze

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
  def self.parse(der, ber: false) # rubocop:disable Metrics:AbcSize
    type = Types.id2type(der)
    type.parse!(der, ber: ber)

    if CONTAINER_CLASSES.include?(type.class)
      subder = type.value
      ary = []
      RASN1.tracer.tracing_level += 1 unless RASN1.tracer.nil?
      until subder.empty?
        ary << self.parse(subder)
        subder = subder[ary.last.to_der.size..-1]
      end
      RASN1.tracer.tracing_level -= 1 unless RASN1.tracer.nil?
      type.value = ary
    end
    type
  end
end
