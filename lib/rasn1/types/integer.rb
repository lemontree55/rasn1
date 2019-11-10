# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Integer
    # @author Sylvain Daubert
    class Integer < Primitive
      # @return [Hash,nil]
      attr_reader :enum

      TAG = 0x02

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
        opts = value_or_options.is_a?(Hash) ? value_or_options : options
        @enum = opts[:enum]

        return if @enum.nil?

        # To ensure @value has the correct type
        self.value = @value

        case @default
        when String,Symbol
          unless @enum.key? @default
            raise EnumeratedError, "TAG #{@name}: unknwon enumerated default value #@{default}"
          end
        when ::Integer
          if @enum.value? @default
            @default = @enum.key(@default)
          else
            raise EnumeratedError, "TAG #{@name}: default value #@{default} not in enumeration"
          end
        when nil
        else
          raise TypeError, "TAG #{@name}: #{@default.class} not handled as default value"
        end
      end

      # @param [Integer,String,Symbol,nil] v
      # @return [String,Symbol,nil]
      def value=(v)
        case v
        when String,Symbol
          raise EnumeratedError, "TAG #{@name} has no :enum" if @enum.nil?

          unless @enum.key? v
            raise EnumeratedError, "TAG #{@name}: unknwon enumerated value #{v}"
          end
          @value = v
        when ::Integer
          if @enum.nil?
            @value = v
          elsif @enum.value? v
            @value = @enum.key(v)
          else
            raise EnumeratedError, "TAG #{@name}: #{v} not in enumeration"
          end
        when nil
          @value = nil
        else
          raise EnumeratedError, "TAG #{@name}: not in enumeration"
        end
      end

      # Integer value
      # @return [Integer]
      def to_i
        if @enum.nil?
          @value || @default || 0
        else
          @enum[@value || @default] || 0
        end
      end

      private

      def int_value_to_der(value=nil)
        v = value || @value
        size = v.bit_length / 8 + ((v.bit_length % 8).positive? ? 1 : 0)
        size = 1 if size.zero?
        comp_value = if v.positive?
                       # If MSB is 1, increment size to set initial octet
                       # to 0 to amrk it as a positive integer
                       size += 1 if v >> (size * 8 - 1) == 1
                       v
                     else
                       ~v.abs + 1
                     end
        ary = []
        size.times { ary << (comp_value & 0xff); comp_value >>= 8 }
        ary.reverse.pack('C*')
      end

      def value_to_der
        case @value
        when String, Symbol
          int_value_to_der @enum[@value]
        when ::Integer
          int_value_to_der
        else
          raise TypeError, "TAG #{@name}: #{@value.class} not handled"
        end
      end

      def der_to_int_value(der, ber: false)
        ary = der.unpack('C*')
        v = ary.reduce(0) { |len, b| (len << 8) | b }
        if ary[0] & 0x80 == 0x80
          v = -((~v & ((1 << v.bit_length) - 1)) + 1)
        end
        v
      end

      def der_to_value(der, ber: false)
        @value = der_to_int_value(der, ber: ber)
        return if @enum.nil?

        @value = @enum.key(@value)
        raise EnumeratedError, "TAG #{@name}: value #{v} not in enumeration" if @value.nil?
      end

      def explicit_type
        self.class.new(name: @name, enum: @enum)
      end
    end
  end
end
