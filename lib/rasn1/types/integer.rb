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

      # @option options [Hash] :enum enumeration hash. Keys are names, and values
      #   are integers.
      # @raise [EnumeratedError] +:default+ value is unknown when +:enum+ key is present
      # @see Base#initialize common options to all ASN.1 types
      def initialize(options={})
        super
        initialize_enum(@options[:enum])
      end

      # @param [Integer,String,Symbol,nil] val
      # @return [void]
      def value=(val)
        @no_value = false
        case val
        when String, Symbol
          value_from_string_or_symbol(val)
        when ::Integer
          value_from_integer(val)
        when nil
          @no_value = true
          @value = void_value
        else
          raise EnumeratedError, "#{@name}: not in enumeration"
        end
      end

      # @return [Integer]
      def void_value
        0
      end

      # Integer value
      # @return [Integer]
      def to_i
        if @enum.empty?
          value? ? @value : @default || 0
        else
          @enum[value? ? @value : @default] || 0
        end
      end

      private

      def initialize_enum(enum)
        @enum = enum || {}
        return if @enum.empty?

        # To ensure @value has the correct type
        self.value = @value if value?

        check_enum_default
      end

      def check_enum_default
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

      def value_from_string_or_symbol(val)
        raise EnumeratedError, "#{@name} has no :enum" if @enum.empty?
        raise EnumeratedError, "#{@name}: unknwon enumerated value #{val}" unless @enum.key? val

        @value = val
      end

      def value_from_integer(val)
        if @enum.empty?
          @value = val
        elsif @enum.value? val
          @value = @enum.key(val)
        else
          raise EnumeratedError, "#{@name}: #{val} not in enumeration"
        end
      end

      def int_value_to_der(value)
        size = compute_size(value)
        comp_value = value >= 0 ? value : (~(-value) + 1) & ((1 << (size * 8)) - 1)
        ary = comp_value.digits(256)
        # v is > 0 and its MSBit is 1. Add a 0 byte to mark it as positive
        ary << 0 if value.positive? && (value >> (size * 8 - 1) == 1)
        ary.reverse.pack('C*')
      end

      def compute_size(value)
        size = value.bit_length / 8 + ((value.bit_length % 8).positive? ? 1 : 0)
        size = 1 if size.zero?
        size
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

      def der_to_int_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        ary = der.unpack('C*')
        v = ary.reduce(0) { |len, b| (len << 8) | b }
        v = -((~v & ((1 << v.bit_length) - 1)) + 1) if ary[0] & 0x80 == 0x80
        v
      end

      def int_to_enum(int, check_enum: true)
        raise EnumeratedError, "#{@name}: value #{int} not in enumeration" if check_enum && !@enum.value?(int)

        @enum.key(int) || int
      end

      def der_to_value(der, ber: false)
        @value = der_to_int_value(der, ber: ber)
        return if @enum.empty?

        @value = int_to_enum(@value)
      end

      def explicit_type
        self.class.new(name: name, enum: enum)
      end

      def trace_data
        return super if explicit?
        return "    #{der_to_int_value(raw_data)} (0x#{raw_data.unpack1('H*')})" if @enum.empty?

        v = int_to_enum(der_to_int_value(raw_data), check_enum: false)
        "    #{v} (0x#{raw_data.unpack1('H*')})"
      end
    end
  end
end
