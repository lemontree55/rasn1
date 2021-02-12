# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Integer
    # @author Sylvain Daubert
    class Integer < Primitive
      # @return [Hash,nil]
      attr_reader :enum

      # Integer id value
      ID = 2

      # @overload initialize(options={})
      #   @option options [Hash] :enum enumeration hash. Keys are names, and values
      #     are integers.
      #   @raise [EnumeratedError] +:default+ value is unknown when +:enum+ key is present
      # @overload initialize(value, options={})
      #   @param [Object] value value to set for this ASN.1 object
      #   @option options [Hash] :enum enumeration hash. Keys are names, and values
      #     are integers. This key is mandatory.
      #   @raise [EnumeratedError] +:default+ value is unknown when +:enum+ key is present
      # @see Base#initialize common options to all ASN.1 types
      def initialize(value_or_options={}, options={})
        super
        @enum = @options[:enum] || {}

        return if @enum.empty?

        # To ensure @value has the correct type
        self.value = @value

        case @default
        when String, Symbol
          raise EnumeratedError, "#{@name}: unknwon enumerated default value #@{default}" unless @enum.key?(@default)
        when ::Integer
          raise EnumeratedError, "#{@name}: default value #@{default} not in enumeration" unless @enum.value?(@default)

          @default = @enum.key(@default)
        when nil
        else
          raise TypeError, "#{@name}: #{@default.class} not handled as default value"
        end
      end

      # @param [Integer,String,Symbol,nil] v
      # @return [void]
      def value=(val)
        case val
        when String, Symbol
          raise EnumeratedError, "#{@name} has no :enum" if @enum.empty?
          raise EnumeratedError, "#{@name}: unknwon enumerated value #{val}" unless @enum.key? val

          @value = val
        when ::Integer
          if @enum.empty?
            @value = val
          elsif @enum.value? val
            @value = @enum.key(val)
          else
            raise EnumeratedError, "#{@name}: #{val} not in enumeration"
          end
        when nil
          @value = nil
        else
          raise EnumeratedError, "#{@name}: not in enumeration"
        end
      end

      # Integer value
      # @return [Integer]
      def to_i
        if @enum.empty?
          @value || @default || 0
        else
          @enum[@value || @default] || 0
        end
      end

      private

      def int_value_to_der(value)
        v = value
        size = v.bit_length / 8 + ((v.bit_length % 8).positive? ? 1 : 0)
        size = 1 if size.zero?
        comp_value = v >= 0 ? v : (~(-v) + 1) & ((1 << (size * 8)) - 1)
        ary = comp_value.digits(256)
        # v is > 0 and its MSBit is 1. Add a 0 byte to mark it as positive
        ary << 0 if v.positive? && (v >> (size * 8 - 1) == 1)
        ary.reverse.pack('C*')
      end

      def value_to_der
        case @value
        when String, Symbol
          int_value_to_der(@enum[@value])
        when ::Integer
          int_value_to_der(@value)
        else
          raise TypeError, "#{@name}: #{@value.class} not handled"
        end
      end

      def der_to_int_value(der, ber: false)
        ary = der.unpack('C*')
        v = ary.reduce(0) { |len, b| (len << 8) | b }
        v = -((~v & ((1 << v.bit_length) - 1)) + 1) if ary[0] & 0x80 == 0x80
        v
      end

      def der_to_value(der, ber: false)
        @value = der_to_int_value(der, ber: ber)
        return if @enum.empty?

        @value = @enum.key(@value)
        raise EnumeratedError, "#{@name}: value #{v} not in enumeration" if @value.nil?
      end

      def explicit_type
        self.class.new(name: @name, enum: @enum)
      end
    end
  end
end
