# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 sequence
    #
    # A sequence is a collection of another ASN.1 types.
    #
    # To encode this ASN.1 example:
    #  Record ::= SEQUENCE {
    #    id        INTEGER,
    #    room  [0] INTEGER OPTIONAL,
    #    house [1] IMPLICIT INTEGER DEFAULT 0
    #  }
    # do:
    #  seq = RASN1::Types::Sequence.new
    #  seq.value = [
    #               RASN1::Types::Integer.new
    #               RASN1::Types::Integer.new(explicit: 0, optional: true),
    #               RASN1::Types::Integer.new(implicit: 1, default: 0)
    #              ]
    #
    # A sequence may also be used without value to not parse sequence content:
    #  seq = RASN1::Types::Sequence.new(:seq)
    #  seq.parse!(der_string)
    #  seq.value    # => String
    # @author Sylvain Daubert
    class Sequence < Constructed
      # Sequence id value
      ID = 0x10

      # @see Base#initialize
      def initialize(options={})
        super
        @no_value = false
        @value ||= []
      end

      # Deep copy @value
      def initialize_copy(*)
        super
        @value = case @value
                 when Array
                   @value.map(&:dup)
                 else
                   @value.dup
                 end
      end

      # @return [Array]
      def void_value
        []
      end

      # Get element at index +idx+, or element of name +name+
      # @param [Integer, String, Symbol] idx_or_name
      # @return [Object,nil]
      def [](idx_or_name)
        return unless @value.is_a?(Array)

        case idx_or_name
        when ::Integer
          @value[idx_or_name.to_i]
        when String, Symbol
          @value.find { |elt| elt.name == idx_or_name }
        end
      end

      private

      def value_to_der
        case @value
        when Array
          @value.map(&:to_der).join
        else
          @value.to_s
        end
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        if @value.is_a?(Array) && !@value.empty?
          nb_bytes = 0
          @value.each do |element|
            nb_bytes += element.parse!(der[nb_bytes..-1])
          end
        else
          @value = der
          der.length
        end
      end

      def trace_data
        ''
      end

      def explicit_type
        self.class.new(name: name, value: @value)
      end
    end
  end
end
