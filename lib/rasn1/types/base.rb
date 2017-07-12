module Rasn1
  module Types

    # @abstract This is base class for all ASN.1 types.
    #   
    #   Subclasses SHOULD define:
    #   * a TAG constant defining ASN.1 tag number,
    #   * a private method {#value_to_der} converting its {#value} to DER,
    #   * a private method {#der_to_value} converting DER into {#value}.
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

      # Length value for indefinite length
      INDEFINITE_LENGTH = 0x80

      # @return [Symbol, String]
      attr_reader :name
      # @return [Symbol]
      attr_reader :asn1_class
      # @return [Object,nil] default value, if defined
      attr_reader :default
      # @return [Object]
      attr_accessor :value

      def self.type
        return @type if @type
        @type = self.to_s.gsub(/.*::/, '').upcase
      end


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

      # @abstract This method SHOULD be partly implemented by subclasses, which
      #   SHOULD respond to +#value_to_der+.
      # @return [String] DER-formated string
      def to_der
        if self.class.const_defined?('TAG')
          build_tag
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

      # Get ASN.1 type
      # @return [String]
      def type
        self.class.type
      end

      # @abstract This method SHOULD be partly implemented by subclasses to parse
      #  data. Subclasses SHOULD respond to +#der_to_value+.
      # Parse a DER string. This method updates object.
      # @param [String] DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [void]
      # @raise [ASN1Error] error on parsing
      def parse!(der, ber: false)
        tag = der[0, 1]
        length = der[1, 1].unpack('C').first
        if tag != encode_tag
          if optional?
            @value = nil
          elsif !@default.nil?
            @value = @default
          else
            raise_tag_error(encode_tag, tag)
          end
          return
        end

        if length == INDEFINITE_LENGTH
          if primitive?
            raise ASN1Error, "malformed #{type} TAG (#@name): indefinite length forbidden for primitive types"
          else
            if ber
              raise NotImplementedError, "TAG #@name: indefinite length not supported yet"
            else
              raise ASN1Error, "TAG #@name: indefinite length forbidden in DER encoding"
            end
          end
        elsif length < INDEFINITE_LENGTH
          der_to_value(der[2, length], ber: ber)
        else
          length = der[2, length & 0x7f].unpack('C*').reduce(0) { |len, b| (len << 8) & b }
          der_to_value(der[2, length], ber: ber)
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

      def build_tag
        if (!@default.nil? and @value == @default) or (optional? and @value.nil?)
          ''
        else
          encoded_value = value_to_der
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
        if size >= INDEFINITE_LENGTH
          bytes = []
          while size > 255
            bytes << (size & 0xff)
            size >>= 8
          end
          bytes << size
          bytes.reverse!
          bytes.unshift(INDEFINITE_LENGTH | bytes.size)
          bytes.pack('C*')
        else
          [size].pack('C')
        end
      end

      def raise_tag_error(expected_tag, tag)
        msg = "Expected tag #{tag2name(expected_tag)} but get #{tag2name(tag)}"
        msg << " for #@name"
        raise ASN1Error, msg
      end

      def tag2name(tag)
        itag = tag.unpack('C').first
        name = CLASSES.key(itag & 0xc0).to_s.upcase
        name << " #{itag & Constructed::ASN1_PC > 0 ? 'CONSTRUCTED' : 'PRIMITIVE'}"
        type =  Types.constants.map { |c| Types.const_get(c) }.
          select { |klass| klass < Primitive || klass < Constructed }.
          find { |klass| klass::TAG == itag & 0x1f }
        name << " #{type.nil? ? "0x%02X" % (itag & 0x1f) : type.type }"
      end
    end
  end
end
