module RASN1
  module Types

    # ASN.1 Enumerated
    #
    # An enumerated type permits to assign names to integer values. It may be defined
    # different ways:
    #  enum = RASN1::Types::Enumerated.new(:name, enum: { 'a' => 0, 'b' => 1, 'c' => 2 })
    #  enum = RASN1::Types::Enumerated.new(:name, enum: { a: 0, b: 1, c: 2 })
    # Its value should be setting as an Integer or a String/symbol:
    #  enum.value = :b
    #  enum.value = 1   # equivalent to :b
    # But its value is always stored as named integer:
    #  enum.value = :b
    #  enum.value      # => :b
    #  enum.value = 0
    #  enum.value      # => :a
    # A {EnumeratedError} is raised when set value is not in enumeration.
    # @author Sylvain Daubert
    class Enumerated < Integer
      # @return [Hash]
      attr_reader :enum

      # @param [Symbol, String] name name for this tag in grammar
      # @param [Hash] options
      # @option options [Symbol] :class ASN.1 tag class. Default value is +:universal+
      # @option options [::Boolean] :optional define this tag as optional. Default
      #   is +false+
      # @option options [Object] :default default value for DEFAULT tag
      # @option options [Hash] :enum enumeration hash. Keys are names, and values
      #   are integers. This key is mandatory.
      # @raise [EnumeratedError] +:enum+ key is not present
      # @raise [EnumeratedError] +:default+ value is unknown
      def initialize(name, options={})
        super
        raise EnumeratedError, 'no enumeration given' unless options.has_key? :enum
        @enum = options[:enum]

        case @default
        when String,Symbol
          unless @enum.has_key? @default
            raise EnumeratedError, "TAG #@name: unknwon enumerated default value #@default"
          end
        when ::Integer
          if @enum.has_value? @default
            @default = @enum.key(@default)
          else
            raise EnumeratedError, "TAG #@name: default value #@defalt not in enumeration"
          end
        when nil
        else
          raise TypeError, "TAG #@name: #{@value.class} not handled as default value"
        end
      end

      # @param [Integer,String,Symbol,nil] v
      # @return [String,Symbol,nil]
      def value=(v)
        case v
        when String,Symbol
          unless @enum.has_key? v
            raise EnumeratedError, "TAG #@name: unknwon enumerated value #{v}"
          end
          @value = v
        when ::Integer
          unless @enum.has_value? v
            raise EnumeratedError, "TAG #@name: #{v} not in enumeration"
          end
          @value = @enum.key(v)
        when nil
          @value = nil
        else
          raise EnumeratedError, "TAG #@name: not in enumeration"
        end
      end

      # @return [Integer]
      def to_i
        case @value
        when String, Symbol
            @enum[@value]
        when ::Integer
          super
        when nil
          if @default
            @enum[@default]
          else
            0
          end
        else
          raise TypeError, "TAG #@name: #{@value.class} not handled"
        end
      end

      # @return [Hash]
      def to_h
        @enum
      end

      private

      def value_to_der
        case @value
        when String, Symbol
          super @enum[@value]
        when ::Integer
          super
        else
          raise TypeError, "TAG #@name: #{@value.class} not handled"
        end
      end

      def der_to_value(der, ber:false)
        super
        v = @value
        @value = @enum.key(v)
        raise EnumeratedError, "TAG #@name: value #{v} not in enumeration" if @value.nil?
      end
    end
  end
end
