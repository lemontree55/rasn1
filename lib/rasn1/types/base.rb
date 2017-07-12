module Rasn1
  module Types

    # @abstract This is base class for all ASN.1 types.
    #   
    #   Subclasses SHOULD define:
    #   * a TAG constant defining ASN.1 tag number,
    #   * a private method {#value_to_der} converting its {#value} to DER.
    # @author Sylvain Daubert
    class Base
      # Allowed ASN.1 tag classes
      CLASSES = {
                 universal:   0x00,
                 application: 0x40,
                 context:     0x80,
                 private:     0xc0
                }

      # Maximum ASN.1 tag number
      MAX_TAG = 0x1e

      # @return [Symbol, String]
      attr_reader :name
      # @return [Symbol]
      attr_reader :asn1_class
      # @return [Object,nil] default value, if defined
      attr_reader :default
      # @return [Object]
      attr_accessor :value

      # @param [Symbol, String] name name for this tag in grammar
      # @param [Hash] options
      # @option options [Symbol] :class ASN.1 tag class. Default value is +:universal+
      # @option options [::Boolean] :optional define this tag as optional. Default
      #   is +false+
      # @option options [Object] :default default value for DEFAULT tag
      def initialize(name, options={})
        @name = name

        set_options options
      end

      # @return [::Boolean]
      def optional?
        @optional
      end

      # @return [String] DER-formated string
      def to_der
        if self.class.const_defined?('TAG')
          build_tag value_to_der
        else
          raise NotImplementedError, 'should be implemented by subclasses'
        end
      end

      # @return [::Boolean] +true+ if this is a primitive type
      def primitive?
        if self.class < Primitive
          true
        else
          false
        end
      end

      # @return [::Boolean] +true+ if this is a constructed type
      def constructed?
        if self.class < Constructed
          true
        else
          false
        end
      end


      private

      def set_options(options)
        set_class options[:class]
        set_optional options[:optional]
        set_default options[:default]
      end

      def set_class(asn1_class)
        case asn1_class
        when nil
          @asn1_class = :universal
        when Symbol
          if CLASSES.keys.include? asn1_class
            @asn1_class = asn1_class
          else
            raise ClassError
          end
        else
          raise ClassError
        end
      end

      def set_optional(optional)
        @optional = !!optional
      end

      def set_default(default)
        @default = default
      end

      def build_tag(encoded_value)
        if (!@default.nil? and @value == @default) or (optional? and @value.nil?)
          ''
        else
          encode_tag << encode_size(encoded_value.size) << encoded_value
        end
      end

      def encode_tag
        tag = self.class::TAG
        if tag <= MAX_TAG
          [tag | CLASSES[@asn1_class] | self.class::ASN1_PC].pack('C')
        else
          raise ASN1Error, 'multi-byte tag value are not supported'
        end
      end

      def encode_size(size)
        if size >= 0x80
          bytes = []
          while size > 255
            bytes << (size & 0xff)
            size >>= 8
          end
          bytes << size
          bytes.reverse!
          bytes.unshift(0x80 | bytes.size)
          bytes.pack('C*')
        else
          [size].pack('C')
        end
      end
    end
  end
end
