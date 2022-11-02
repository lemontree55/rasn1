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
  class Wrapper < SimpleDelegator
    # @private Private class used to build/parse explicit wrappers
    class ExplicitWrapper < Types::Base
      ID = 0 # not used
      ASN1_PC = 0 # not constructed

      def self.type
        ''
      end

      private

      def value_to_der
        @value.is_a?(String) ? @value : @value.to_der
      end
    end

    # @param [Class] klass a Types::Base or Model class
    # @param [Hash] options
    def initialize(element, options={})
      opts = options.dup
      @explicit = opts.delete(:explicit)
      @implicit = opts.delete(:implicit)
      if explicit?
        @options = opts
        # ExplicitWrapper is a hand-made explicit tag, but we have to use its implicit option
        # to force its tag value.
        @explicit_wrapper = ExplicitWrapper.new(opts.merge(implicit: @explicit))
        #element = ExplicitWrapper.new(opts.merge(implicit: @explicit, value: element))
      else
        opts[:value] = element.value
        element.options = element.options.merge(opts)
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
        el = generate_implicit_element
        el.to_der
      elsif explicit?
        @explicit_wrapper.value = element
        @explicit_wrapper.to_der
      else
        element.to_der
      end
    end

    # Parse a DER string. This method updates object.
    # @param [String] der DER string
    # @param [Boolean] ber if +true+, accept BER encoding
    # @return [Integer] total number of parsed bytes
    # @raise [ASN1Error] error on parsing
    def parse!(der, ber: false)
      if implicit?
        el = generate_implicit_element
        parsed = el.parse!(der, ber: ber)
        element.value = el.value
        parsed
      elsif explicit?
        parsed = @explicit_wrapper.parse!(der, ber: ber)
        element.parse!(@explicit_wrapper.value, ber: ber)
        parsed
      else
        element.parse!(der, ber: ber)
      end
    end

    # Return Wrapped element
    # @return [Types::Base,Model]
    def element
      __getobj__
    end

    # @return [::Integer]
    def id
      if implicit?
        @implicit
      elsif explicit?
        @explicit
      else
        element.id
      end
    end

    # @return [Symbol]
    def asn1_class
      return element.asn1_class unless @options.key?(:class)

      @options[:class]
    end

    # @return [Boolean]
    def constructed?
      return element.constructed? unless @options.key?(:constructed)

      @options[:constructed]
    end

    # @return [Boolean]
    def primitive?
      !constructed?
    end

    private

    def generate_implicit_element
      el = element.dup
      if el.explicit?
        el.options = el.options.merge(explicit: @implicit)
      elsif el.implicit?
        el.options = el.options.merge(implicit: @implicit)
      end
      el
    end
  end
end
