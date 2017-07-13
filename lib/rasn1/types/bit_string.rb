module Rasn1
  module Types

    # ASN.1 Bit String
    # @author Sylvain Daubert
    class BitString < Primitive
      TAG = 0x03

      # @return [Integer] bit length of bit string
      attr_accessor :bit_length

      # @param [Symbol, String] name name for this tag in grammar
      # @param [Hash] options
      # @option options [Symbol] :class ASN.1 tag class. Default value is +:universal+
      # @option options [::Boolean] :optional define this tag as optional. Default
      #   is +false+
      # @option options [Object] :default default value for DEFAULT tag
      # @option options [Object] :bit_length default bit_length value. Should be
      #   present if +:default+ is set
      def initialize(name, options={})
        super
        if @default
          if options[:bit_length].nil?
            raise ASN1Error, "TAG #@name: default bit length is not defined"
          end
          @default_bit_length = options[:bit_length]
        end
      end

      private

      def build_tag?
        !(!@default.nil? and @value == @default and
          @bit_length == @default_bit_length) and
          !(optional? and @value.nil?)
      end

      def value_to_der
        raise ASN1Error, "TAG #@name: bit length is not set" if @bit_length.nil?

        while @value.length * 8 < @bit_length
          @value << "\x00"
        end
        @value.force_encoding('BINARY')

        if @value.length * 8 > @bit_length
          max_len = @bit_length / 8 + (@bit_length % 8 > 0 ? 1 : 0)
          @value = @value[0, max_len]
        end

        unused = @value.length * 8 - @bit_length
        der = [unused, @value].pack('CA*')

        if unused > 0
          last_byte = @value[-1].unpack('C').first
          last_byte &= (0xff >> unused) << unused
          der[-1] = [last_byte].pack('C')
        end

        der
      end

      def der_to_value(der, ber:false)
        unused, @value = der.unpack('CA*')
        @bit_length = @value.length * 8 - unused
      end
    end
  end
end

