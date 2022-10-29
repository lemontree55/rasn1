# frozen_string_literal: true

require 'delegate'

module RASN1
  # This class is used to wrap a {Types::Base} or {Model} instance to force its options.
  #
  # == Usage
  # This class may be used to wrap another RASN1 object by 3 ways:
  # * wrap an object to modify its options,
  # * implicitly wrap an object (i.e. change its tag),
  # * explicitly wrap an object (i.e wrap the object in another explicit ASN.1 tag)
  #
  # @example
  #   # object to wrap
  #   int = RASN1::Types::Integer.new(implicit: 1)    # its tag is 0x81
  #   # simple wraper, change an option
  #   wrapper = RASN1::Wrapper.new(int, optional: true, default: 1)
  #   # implicit wrapper
  #   wrapper = RASN1::Wrapper.new(int, implicit: 3)  # wrapped int tag is now 0x83
  #   # explicit wrapper
  #   wrapper = RASN1::Wrapper.new(int, explicit: 4)  # int tag is always 0x81, but it is wrapped in a 0x84 tag
  # @since 0.12.0
  class Wrapper < Delegator
    # @private Private class used to build/parse explicit wrappers
    class ExplicitWrapper < Types::Base
      ID = 0 # not used
      ASN1_PC = 0 # not constructed

      def self.type
        ''
      end

      private

      def value_to_der
        @value.to_der
      end
    end

    # @param [Class] klass a Types::Base or Model class
    # @param [Hash] options
    def initialize(element, options={})
      @explicit = options.delete(:explicit)
      @implicit = options.delete(:implicit)
      if explicit?
        @options = options
        # ExplicitWrapper is a hand-made explicit tag, but we have to use its implicit option
        # to force its tag value.
        element = ExplicitWrapper.new(options.merge(implicit: @explicit, value: element))
      else
        options[:value] = element.value
        element.options = element.options.merge(options)
        @options = {}
      end
      raise RASN1::Error, 'Cannot be implicit and explicit' if explicit? && implicit?

      super(element)
    end

    # Say if wrapper is an explicit one (i.e. add tag and length to its element)
    # @return [Boolean]
    def explicit?
      !!@explicit
    end

    # Say if wrapper is an implicit one (i.e. change tag of its element)
    # @return [Boolean]
    def implicit?
      !!@implicit
    end

    # Convert wrapper and its element to a DER string
    # @return [String]
    def to_der
      if implicit?
        element = generate_implicit_element
        element.to_der
      else
        @element.to_der
      end
    end

    # Parse a DER string. This method updates object.
    # @param [String] der DER string
    # @param [Boolean] ber if +true+, accept BER encoding
    # @return [Integer] total number of parsed bytes
    # @raise [ASN1Error] error on parsing
    def parse!(der, ber: false)
      if implicit?
        element = generate_implicit_element
        parsed = element.parse!(der, ber: ber)
        @element.value = element.value
        parsed
      elsif explicit?
        real_element = @element.value
        parsed = @element.parse!(der, ber: ber)
        real_element.parse!(@element.value, ber: ber)
        @element.value = real_element
        parsed
      else
        @element.parse!(der, ber: ber)
      end
    end

    private

    def generate_implicit_element
      element = @element.dup
      if element.explicit?
        element.options = element.options.merge(explicit: @implicit)
      elsif element.implicit?
        element.options = element.options.merge(implicit: @implicit)
      end
      element
    end

    def __getobj__
      @element
    end

    def __setobj__(obj)
      @element = obj
    end
  end
end
