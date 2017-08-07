module RASN1
  module Types

    # ASN.1 ANY: accpets any types
    # @author Sylvain Daubert
    class Any < Base

      # @return [String] DER-formated string
      def to_der
        @value.to_s
      end

      # Parse a DER string. This method updates object: {#value} will a DER string.
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
