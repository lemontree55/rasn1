# frozen_string_literal: true

require_relative 'rasn1/version'
require_relative 'rasn1/errors'
require_relative 'rasn1/types'
require_relative 'rasn1/model'
require_relative 'rasn1/wrapper'
require_relative 'rasn1/tracer'

# Constrained types
require_relative 'rasn1/types/visible_string'

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
  # @return [Types::Base, Array[Types::Base]]
  def self.parse(der, ber: false) # rubocop:disable Metrics/AbcSize
    result = []
    until der.nil? || der.empty?
      type = Types.id2type(der)
      size = type.parse!(der, ber: ber)

      if CONTAINER_CLASSES.include?(type.class)
        RASN1.tracer.tracing_level += 1 unless RASN1.tracer.nil?
        content = self.parse(type.value)
        type.value = content.is_a?(Array) ? content : [content]
        RASN1.tracer.tracing_level -= 1 unless RASN1.tracer.nil?
      end

      result << type
      der = der[size..]
    end

    result.size == 1 ? result[0] : result
  end
end
