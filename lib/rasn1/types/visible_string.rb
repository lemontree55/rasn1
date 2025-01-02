# frozen_string_literal: true

module RASN1
  module Types
    # Create VisibleString as a Constrained subclass of IA5String
    Types.define_type(:VisibleString, from: IA5String) do |value|
      value.nil? || value.chars.all? { |c| c.ord >= 32 && c.ord <= 126 }
    end

    # ASN.1 Visible String
    #
    # VisibleString may only contain ASCII characters from range 32 to 126.
    # @author LemonTree55
    # @since 0.3.0
    # @since 0.15.0 VisibleString is defined as a constrained {IA5String}. It will now raise if value contains a non-visible character.
    class VisibleString
      # VisibleString id value
      # @since 0.3.0
      ID = 26

      # Get ASN.1 type
      # @return [String]
      # @author Sylvain Daubert
      # @since 0.3.0
      def self.type
        'VisibleString'
      end
    end
  end
end
