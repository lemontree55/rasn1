# frozen_string_literal: true

module RASN1
  module Types
    # @abstract This is base class for all ASN.1 types.
    #
    #   Subclasses SHOULD define:
    #   * an ID constant defining ASN.1 BER/DER identification number,
    #   * a private method {#value_to_der} converting its {#value} to DER,
    #   * a private method {#der_to_value} converting DER into {#value}.
    #
    # ==Define an optional value
    # An optional value may be defined using +:optional+ key from {#initialize}:
    #   Integer.new(:int, optional: true)
    # An optional value implies:
    # * while parsing, if decoded ID is not optional expected ID, no {ASN1Error}
    #   is raised, and parser tries next field,
    # * while encoding, if {#value} is +nil+, this value is not encoded.
    # ==Define a default value
    # A default value may be defined using +:default+ key from {#initialize}:
    #  Integer.new(:int, default: 0)
    # A default value implies:
    # * while parsing, if decoded ID is not expected one, no {ASN1Error} is raised
    #   and parser sets default value to this ID. Then parser tries next field,
    # * while encoding, if {#value} is equal to default value, this value is not
    #   encoded.
    # ==Define a tagged value
    # ASN.1 permits to define tagged values.
    # By example:
    #  -- context specific tag
    #  CType ::= [0] EXPLICIT INTEGER
    #  -- application specific tag
    #  AType ::= [APPLICATION 1] EXPLICIT INTEGER
    #  -- private tag
    #  PType ::= [PRIVATE 2] EXPLICIT INTEGER
    # These types may be defined as:
    #  ctype = RASN1::Types::Integer.new(explicit: 0)                      # with explicit, default #asn1_class is :context
    #  atype = RASN1::Types::Integer.new(explicit: 1, class: :application)
    #  ptype = RASN1::Types::Integer.new(explicit: 2, class: :private)
    # Sometimes, an EXPLICIT type should be CONSTRUCTED. To do that, use +:constructed+
    # option:
    #  ptype = RASN1::Types::Integer.new(explicit: 2, class: :private, constructed: true)
    #
    # Implicit tagged values may also be defined:
    #  ctype_implicit = RASN1::Types::Integer.new(implicit: 0)
    # @author Sylvain Daubert
    class Base # rubocop:disable Metrics/ClassLength
      # Allowed ASN.1 classes
      CLASSES = {
        universal: 0x00,
        application: 0x40,
        context: 0x80,
        private: 0xc0
      }.freeze

      # Binary mask to get class
      # @private
      CLASS_MASK = 0xc0

      # @private first octet identifier for multi-octets identifier
      MULTI_OCTETS_ID = 0x1f

      # Length value for indefinite length
      INDEFINITE_LENGTH = 0x80

      # @return [String,nil]
      attr_reader :name
      # @return [Symbol]
      attr_reader :asn1_class
      # @return [Object,nil] default value, if defined
      attr_reader :default

      # Get ASN.1 type
      # @return [String]
      def self.type
        return @type if defined? @type

        @type = self.to_s.gsub(/.*::/, '').gsub(/([a-z0-9])([A-Z])/, '\1 \2').upcase
      end

      # Get ASN.1 type used to encode this one
      # @return [String]
      def self.encoded_type
        type
      end

      # Parse a DER or BER string
      # @param [String] der_or_ber string to parse
      # @param [Hash] options
      # @option options [Boolean] :ber if +true+, parse a BER string, else a DER one
      # @note More options are supported. See {Base#initialize}.
      def self.parse(der_or_ber, options={})
        obj = self.new(options)
        obj.parse!(der_or_ber, ber: options[:ber])
        obj
      end

      # @param [Hash] options
      # @option options [Symbol] :class ASN.1 class. Default value is +:universal+.
      #  If +:explicit+ or +:implicit:+ is defined, default value is +:context+.
      # @option options [::Boolean] :optional define this tag as optional. Default
      #   is +false+
      # @option options [Object] :default default value (ASN.1 DEFAULT)
      # @option options [Object] :value value to set
      # @option options [::Integer] :implicit define an IMPLICIT tagged type
      # @option options [::Integer] :explicit define an EXPLICIT tagged type
      # @option options [::Boolean] :constructed if +true+, set type as constructed.
      #  May only be used when +:explicit+ is defined, else it is discarded.
      # @option options [::String] :name name for this node
      def initialize(options={})
        @constructed = nil
        set_options options
      end

      # Used by +#dup+ and +#clone+. Deep copy @value and @default.
      def initialize_copy(_other)
        @value = @value.dup
        @no_value = @no_value.dup
        @default = @default.dup
      end

      # Get value or default value
      def value
        if value?
          @value
        else
          @default
        end
      end

      # Set value. If +val+ is +nil+, unset value
      # @param [Object,nil] val
      def value=(val)
        set_value(val)
      end

      # @abstract Define 'void' value (i.e. 'value' when no value was set)
      def void_value
        ''
      end

      # @return [::Boolean]
      def optional?
        @optional
      end

      # Say if this type is tagged or not
      # @return [::Boolean]
      def tagged?
        !@tag.nil?
      end

      # Say if a tagged type is explicit
      # @return [::Boolean,nil] return +nil+ if not tagged, return +true+
      #   if explicit, else +false+
      def explicit?
        defined?(@tag) ? @tag == :explicit : nil
      end

      # Say if a tagged type is implicit
      # @return [::Boolean,nil] return +nil+ if not tagged, return +true+
      #   if implicit, else +false+
      def implicit?
        defined?(@tag) ? @tag == :implicit : nil
      end

      # @abstract This method SHOULD be partly implemented by subclasses, which
      #   SHOULD respond to +#value_to_der+.
      # @return [String] DER-formated string
      def to_der
        build
      end

      # @return [::Boolean] +true+ if this is a primitive type
      def primitive?
        (self.class < Primitive) && !@constructed
      end

      # @return [::Boolean] +true+ if this is a constructed type
      def constructed?
        (self.class < Constructed) || !!@constructed
      end

      # Get ASN.1 type
      # @return [String]
      def type
        self.class.type
      end

      # Get identifier value
      # @return [Integer]
      def id
        id_value
      end

      # @abstract This method SHOULD be partly implemented by subclasses to parse
      #  data. Subclasses SHOULD respond to +#der_to_value+.
      # Parse a DER string. This method updates object.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      # @raise [ASN1Error] error on parsing
      def parse!(der, ber: false)
        return 0 unless check_id(der)

        id_size = Types.decode_identifier_octets(der).last
        total_length, data = get_data(der[id_size..-1], ber)
        total_length += id_size
        @no_value = false
        if explicit?
          # Delegate to #explicit type to generate sub-value
          type = explicit_type
          type.parse!(data)
          @value = type.value
        else
          der_to_value(data, ber: ber)
        end

        total_length
      end

      # Give size in octets of encoded value
      # @return [Integer]
      def value_size
        value_to_der.size
      end

      # @param [Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << ' ' << inspect_value
        str << ' OPTIONAL' if optional?
        str << " DEFAULT #{@default}" unless @default.nil?
        str
      end

      # Objects are equal if they have same class AND same DER
      # @param [Base] other
      # @return [Boolean]
      def ==(other)
        (other.class == self.class) && (other.to_der == self.to_der)
      end

      private

      def pc_bit
        if @constructed.nil?
          self.class::ASN1_PC
        elsif @constructed # true
          Constructed::ASN1_PC
        else # false
          Primitive::ASN1_PC
        end
      end

      def common_inspect(level)
        lvl = level >= 0 ? level : 0
        str = '  ' * lvl
        str << "#{@name} " unless @name.nil?
        str << asn1_class.to_s.upcase << ' ' unless asn1_class == :universal
        str << "[#{id}] EXPLICIT " if explicit?
        str << "[#{id}] IMPLICIT " if implicit?
        str << "#{type}:"
      end

      def inspect_value
        if value?
          value.inspect
        else
          '(NO VALUE)'
        end
      end

      def value_to_der
        case @value
        when Base
          @value.to_der
        else
          @value.to_s
        end
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        @value = der
      end

      def set_options(options) # rubocop:disable Naming/AccessorMethodName
        set_class options[:class]
        set_optional options[:optional]
        set_default options[:default]
        set_tag options
        set_value options[:value]
        @name = options[:name]
        @options = options
      end

      def set_class(asn1_class) # rubocop:disable Naming/AccessorMethodName
        case asn1_class
        when nil
          @asn1_class = :universal
        when Symbol
          raise ClassError unless CLASSES.key? asn1_class

          @asn1_class = asn1_class
        else
          raise ClassError
        end
      end

      def set_optional(optional) # rubocop:disable Naming/AccessorMethodName
        @optional = !!optional
      end

      def set_default(default) # rubocop:disable Naming/AccessorMethodName
        @default = default
      end

      # handle undocumented option +:tag_value+, used internally by
      # {RASN1.parse} to parse non-universal class tags.
      def set_tag(options) # rubocop:disable Naming/AccessorMethodName
        if options[:explicit]
          @tag = :explicit
          @id_value = options[:explicit]
          @constructed = options[:constructed]
        elsif options[:implicit]
          @tag = :implicit
          @id_value = options[:implicit]
          @constructed = options[:constructed]
        elsif options[:tag_value]
          @id_value = options[:tag_value]
          @constructed = options[:constructed]
        end

        @asn1_class = :context if defined?(@tag) && (@asn1_class == :universal)
      end

      def set_value(value) # rubocop:disable Naming/AccessorMethodName
        if value.nil?
          @no_value = true
          @value = void_value
        else
          @no_value = false
          @value = value
        end
        value
      end

      def value?
        !@no_value
      end

      def can_build?
        (@default.nil? || (value? && (@value != @default))) &&
          (!optional? || value?)
      end

      def build
        if can_build?
          if explicit?
            v = explicit_type
            v.value = @value
            encoded_value = v.to_der
          else
            encoded_value = value_to_der
          end
          encode_identifier_octets << encode_size(encoded_value.size) << encoded_value
        else
          ''
        end
      end

      def id_value
        return @id_value if defined? @id_value

        self.class::ID
      end

      def encode_identifier_octets
        id2octets.pack('C*')
      end

      def id2octets
        first_octet = CLASSES[asn1_class] | pc_bit
        if id < MULTI_OCTETS_ID
          [first_octet | id]
        else
          [first_octet | MULTI_OCTETS_ID] + unsigned_to_chained_octets(id)
        end
      end

      # Encode an unsigned integer on multiple octets.
      # Value is encoded on bit 6-0 of each octet, bit 7(MSB) indicates wether
      # further octets follow.
      def unsigned_to_chained_octets(value)
        ary = []
        while value.positive?
          ary.unshift(value & 0x7f | 0x80)
          value >>= 7
        end
        ary[-1] &= 0x7f
        ary
      end

      def encode_size(size)
        if size >= INDEFINITE_LENGTH
          bytes = []
          while size > 255
            bytes.unshift(size & 0xff)
            size >>= 8
          end
          bytes.unshift(size)
          bytes.unshift(INDEFINITE_LENGTH | bytes.size)
          bytes.pack('C*')
        else
          [size].pack('C')
        end
      end

      def check_id(der)
        expected_id = encode_identifier_octets
        real_id = der[0, expected_id.size]
        return true if real_id == expected_id

        if optional?
          @no_value = true
          @value = void_value
        elsif !@default.nil?
          @value = @default
        else
          raise_id_error(der)
        end
        false
      end

      def get_data(der, ber)
        length = der.unpack1('C').to_i
        length_length = 0

        if length == INDEFINITE_LENGTH
          raise_on_indefinite_length(ber)
        elsif length > INDEFINITE_LENGTH
          length_length = length & 0x7f
          length = der[1, length_length].unpack('C*')
                                        .reduce(0) { |len, b| (len << 8) | b }
        end
        data = der[1 + length_length, length]

        total_length = 1 + length
        total_length += length_length if length_length.positive?

        [total_length, data]
      end

      def raise_on_indefinite_length(ber)
        if primitive?
          raise ASN1Error, "malformed #{type}: indefinite length " \
            'forbidden for primitive types'
        elsif ber
          raise NotImplementedError, 'indefinite length not supported'
        else
          raise ASN1Error, 'indefinite length forbidden in DER encoding'
        end
      end

      def explicit_type
        self.class.new
      end

      def raise_id_error(der)
        msg = name.nil? ? +'' : +"#{name}: "
        msg << "Expected #{self2name} but get #{der2name(der)}"
        raise ASN1Error, msg
      end

      def class_from_numeric_id(id)
        CLASSES.key(id & CLASS_MASK)
      end

      def self2name
        name = +"#{asn1_class.to_s.upcase} #{constructed? ? 'CONSTRUCTED' : 'PRIMITIVE'}"
        if implicit? || explicit?
          name << ' 0x%X (0x%s)' % [id, bin2hex(encode_identifier_octets)]
        else
          name << ' ' << self.class.type
        end
      end

      def der2name(der)
        return 'no ID' if der.nil? || der.empty?

        asn1_class, pc, id, id_size = Types.decode_identifier_octets(der)
        name = +"#{asn1_class.to_s.upcase} #{pc.to_s.upcase}"
        type =  find_type(id)
        name << " #{type.nil? ? '0x%X (0x%s)' % [id, bin2hex(der[0...id_size])] : type.encoded_type}"
      end

      def find_type(id)
        Types.constants.map { |c| Types.const_get(c) }
             .select { |klass| klass < Primitive || klass < Constructed }
             .find { |klass| klass::ID == id }
      end

      def bin2hex(str)
        str.unpack1('H*')
      end
    end
  end
end
