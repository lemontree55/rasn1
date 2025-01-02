# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Octet String
    #
    # An OCTET STRINT may contain another primtive object:
    #  os = OctetString.new
    #  int = Integer.new
    #  int.value = 12
    #  os.value = int
    #  os.to_der   # => DER string with INTEGER in OCTET STRING
    # @author Sylvain Daubert
    class OctetString < Primitive
      # OctetString id value
      ID = 4

      # @param [::Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << " #{value.inspect}"
      end

      # Make string value from +der+ string. Force encoding to UTF-8
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @since 0.15.0 Handle ENCODING constant, if defined by subclass
      def der_to_value(der, ber: false)
        klass = self.class
        if klass.const_defined?(:ENCODING)
          @value = der.to_s.dup.force_encoding(klass.const_get(:ENCODING))
        else
          super
        end
      end

      private

      # @since 0.15.0 Handle ENCODING constant, if defined by subclass
      def value_to_der
        klass = self.class
        if klass.const_defined?(:ENCODING)
          @value.to_s.encode(klass.const_get(:ENCODING)).b
        else
          super
        end
      end
    end
  end
end
