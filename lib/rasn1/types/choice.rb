# frozen_string_literal: true

module RASN1
  module Types
    # A ASN.1 CHOICE is a choice between different types.
    #
    # == Create a CHOICE
    # A CHOICE is defined this way:
    #   choice = Choice.new
    #   choice.value = [Integer.new(implicit: 0, class: :context),
    #                   Integer.new(implicit: 1, class: :context),
    #                   OctetString.new(implicit: 2, class: :context)]
    # The chosen type may be set this way:
    #   choice.chosen = 0   # choose :int1
    # The chosen value may be set these ways:
    #   choise.value[choice.chosen].value = 1
    #   choise.set_chosen_value 1
    # The chosen value may be got these ways:
    #   choise.value[choice.chosen].value # => 1
    #   choice.chosen_value               # => 1
    #
    # == Encode a CHOICE
    # {#to_der} only encodes the chosen value:
    #   choise.to_der   # => "\x80\x01\x01"
    #
    # == Parse a CHOICE
    # Parsing a CHOICE set {#chosen} and set value to chosen type. If parsed string does
    # not contain a type from CHOICE, a {RASN1::ASN1Error} is raised.
    #   str = "\x04\x03abc"
    #   choice.parse! str
    #   choice.chosen        # => 2
    #   choice.chosen_value  # => "abc"
    # @author Sylvain Daubert
    class Choice < Base
      # Chosen type
      # @return [Integer] index of type in choice value
      attr_accessor :chosen

      # Set chosen value.
      # @note {#chosen} MUST be set before calling this method
      # @param [Object] value
      # @return [Object] value
      # @raise [ChoiceError] {#chosen} not set
      def set_chosen_value(value) # rubocop:disable Naming/AccessorMethodName
        check_chosen
        @value[@chosen].value = value
      end

      # Get chosen value
      # @note {#chosen} MUST be set before calling this method
      # @return [Object] value
      # @raise [ChoiceError] {#chosen} not set
      def chosen_value
        check_chosen
        case @value[@chosen]
        when Base
          @value[@chosen].value
        when Model
          @value[@chosen]
        when Wrapper
          @value[@chosen].element
        end
      end

      # @note {#chosen} MUST be set before calling this method
      # @return [String] DER-formated string
      # @raise [ChoiceError] {#chosen} not set
      def to_der
        check_chosen
        @value[@chosen].to_der
      end

      # Parse a DER string. This method updates object by setting {#chosen} and
      # chosen value.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      # @raise [ASN1Error] error on parsing
      def parse!(der, ber: false)
        len, data = do_parse(der, ber: ber)
        return 0 if len.zero?

        element = @value[@chosen]
        if element.explicit?
          element.do_parse_explicit(data)
        else
          element.der_to_value(data, ber: ber)
        end
        len
      end

      # @private
      # @see Types::Base#do_parse
      # @since 0.15.0 Specific +#do_parse+ to handle recursivity
      def do_parse(der, ber: false)
        @value.each_with_index do |element, i|
          @chosen = i
          return element.do_parse(der, ber: ber)
        rescue ASN1Error
          @chosen = nil
          next
        end

        @no_value = true
        @value = void_value
        raise ASN1Error, "CHOICE #{@name}: no type matching #{der.inspect}" unless optional?

        [0, ''.b]
      end

      # Make choice value from DER/BER string.
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @since 0.15.0 Specific +#der_to_value+ to handle recursivity
      def der_to_value(der, ber: false)
        @value.each_with_index do |element, i|
          @chosen = i
          element.parse!(der, ber: ber)
          break
        rescue ASN1Error
          @chosen = nil
          next
        end
      end

      # @param [::Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << if defined?(@chosen) && value?
                 "\n#{@value[@chosen].inspect(level + 1)}"
               else
                 ' not chosen!'
               end
      end

      # @private Tracer private API
      # @return [String]
      def trace
        msg_type(no_id: true)
      end

      # Return empty array
      # @return [Array()]
      # @since 0.15.0
      def void_value
        []
      end

      private

      def check_chosen
        raise ChoiceError.new(self) if !defined?(@chosen) || @chosen.nil?
      end
    end
  end
end
