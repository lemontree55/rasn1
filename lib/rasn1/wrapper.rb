# frozen_string_literal: true

require 'delegate'

module RASN1
  # This class is used to wrap a {Types::Base} or {Model} instance to force its options.
  #
  # == Usage
  # This class may be used to wrap another RASN1 object by 4 ways:
  # * wrap an object to modify its options,
  # * implicitly wrap an object (i.e. change its tag),
  # * explicitly wrap an object (i.e wrap the object in another explicit ASN.1 tag),
  # * wrap a choice model to reuse it in its own definition.
  #
  # @example Wrapping object
  #   # object to wrap
  #   int = RASN1::Types::Integer.new(implicit: 1)    # its tag is 0x81
  #   # simple wrapper, change an option
  #   wrapper = RASN1::Wrapper.new(int, default: 1)
  #   # implicit wrapper
  #   wrapper = RASN1::Wrapper.new(int, implicit: 3)  # wrapped int tag is now 0x83
  #   # explicit wrapper
  #   wrapper = RASN1::Wrapper.new(int, explicit: 4)  # int tag is always 0x81, but it is wrapped in a 0x84 tag
  # @example Wrapping a choice to make it recursive
  #  class RecursiveChoice < RASN1::Model
  #    choice :choice,
  #           content: [
  #             integer(:value, implicit: 1),
  #             wrapper(model(:recursive, RecursiveChoice), implicit:2)
  #           ]
  #  end
  # @since 0.12.0
  # @since 0.15.0 Wrappers are lazy. They allocate their inner element only when needed (i.e. when calling {#to_der}, {#parse!} or {#element})
  # @author Sylvain Daubert
  # @author LemonTree55
  class Wrapper < SimpleDelegator
    # @private Private class used to build/parse explicit wrappers
    class ExplicitWrapper < Types::Base
      ID = 0 # not used
      ASN1_PC = 0 # not constructed

      def self.type
        ''
      end

      # @return [Boolean]
      # @see Types::Base#can_build?
      def can_build?
        ok = super
        return ok unless optional?

        ok && @value.can_build?
      end

      private

      def value_to_der
        @value.is_a?(String) ? @value : @value.to_der
      end

      def inspect_value
        ''
      end
    end

    # @param [Types::Base,Model] element element to wrap
    # @param [Hash] options
    def initialize(element, options={})
      @lazy = true
      opts = explicit_implicit(options)

      if explicit?
        generate_explicit_wrapper(opts)
        @element_options_to_merge = generate_explicit_wrapper_options(opts)
        @options = opts
      else
        opts[:value] = element.value if element.respond_to?(:value)
        @element_options_to_merge = opts
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
    # @since 0.12.0
    # @since 0.15.0 Allocate element (lazy wrapper)
    def to_der
      lazy_generation
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
    # @since 0.12.0
    # @since 0.15.0 Allocate element (lazy wrapper)
    def parse!(der, ber: false)
      lazy_generation
      if implicit?
        el = generate_implicit_element
        parsed = el.parse!(der, ber: ber)
        element.value = el.value
        parsed
      elsif explicit?
        parsed = @explicit_wrapper.parse!(der, ber: ber)
        element.parse!(@explicit_wrapper.value, ber: ber) if parsed.positive?
        parsed
      else
        element.parse!(der, ber: ber)
      end
    end

    # @private
    # @see Types::Base#do_parse
    def do_parse(der, ber: false)
      if implicit?
        generate_implicit_element(Types::Base.new(constructed: element.constructed?)).do_parse(der, ber: ber)
      elsif explicit?
        @explicit_wrapper.do_parse(der, ber: ber)
      else
        element.do_parse(der, ber: ber)
      end
    end

    # @return [Boolean]
    # @see Types::Base#value?
    def value?
      if explicit?
        @explicit_wrapper.value?
      elsif __getobj__.is_a?(Class)
        false
      else
        __getobj__.value?
      end
    end

    # Return Wrapped element
    # @return [Types::Base,Model]
    # @since 0.12.0
    # @since 0.15.0 Allocate element (lazy wrapper)
    def element
      lazy_generation
    end

    # @return [::Integer]
    # @see Types::Base#id
    def id
      if implicit?
        @implicit
      elsif explicit?
        @explicit
      else
        lazy_generation(register: false).id
      end
    end

    # @return [Symbol]
    # @see Types::Base#asn1_class
    def asn1_class
      return lazy_generation(register: false).asn1_class unless @options.key?(:class)

      @options[:class]
    end

    # @return [Boolean]
    # @see Types::Base#constructed
    def constructed?
      return lazy_generation(register: false).constructed? unless @options.key?(:constructed)

      @options[:constructed]
    end

    # @return [Boolean]
    # @see Types::Base#primitive
    def primitive?
      !constructed?
    end

    # @param [::Integer] level
    # @return [String]
    def inspect(level=0)
      return super() unless explicit?

      @explicit_wrapper.inspect(level) << ' ' << super()
    end

    private

    def explicit_implicit(options)
      opts = options.dup
      @explicit = opts.delete(:explicit)
      @implicit = opts.delete(:implicit)
      opts
    end

    def generate_explicit_wrapper(options)
      # ExplicitWrapper is a hand-made explicit tag, but we have to use its implicit option
      # to force its tag value.
      @explicit_wrapper = ExplicitWrapper.new(options.merge(implicit: @explicit))
    end

    def generate_explicit_wrapper_options(options)
      new_opts = {}
      new_opts[:default] = options[:default] if options.key?(:default)
      new_opts[:optional] = options[:optional] if options.key?(:optional)
      new_opts
    end

    def generate_implicit_element(from=nil)
      el = (from || element).dup
      el.options = if element.explicit?
                     el.options.merge(explicit: @implicit)
                   else
                     el.options.merge(implicit: @implicit)
                   end
      el
    end

    def lazy_generation(register: true)
      return __getobj__ unless @lazy

      real_element = __getobj__
      case real_element
      when Types::Base, Model
        real_element.options = real_element.options.merge(@element_options_to_merge)
        @lazy = false
        real_element
      else
        el = real_element.new(@element_options_to_merge)
        if register
          @lazy = false
          __setobj__(el)
        end
        el
      end
    end
  end
end
