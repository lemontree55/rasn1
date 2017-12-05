module RASN1
  module Types

    # ASN.1 ANY: accepts any types
    #
    # If `any#value` is `nil`, `any` will be encoded as a {Null} object.
    # @author Sylvain Daubert
    class Any < Base

      # @return [String] DER-formated string
      def to_der
        case @value
        when Base, Model
          @value.to_der
        when nil
          Null.new(@name).to_der
        else
          @value.to_s
        end
      end

      # Parse a DER string. This method updates object: {#value} will be a DER
      # string.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      def parse!(der, ber: false)
        total_length,  = get_data(der, ber)
        @value = der[0, total_length]
        total_length
      end
    end
  end
end
