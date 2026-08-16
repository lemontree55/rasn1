# frozen_string_literal: true

module RASN2
  module Types
    # @abstract This is base class for all ASN.1 types.
    #
    #   Subclasses SHOULD define:
    #   * an ID constant defining ASN.1 BER/DER identification number,
    #   * a method {#der_to_value} converting DER into {#value}.
    #   * a private method {#value_to_der} converting its {#value} to DER,
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
    #  ctype = RASN2::Types::Integer.new(explicit: 0)                      # with explicit, default #asn1_class is :context
    #  atype = RASN2::Types::Integer.new(explicit: 1, class: :application)
    #  ptype = RASN2::Types::Integer.new(explicit: 2, class: :private)
    # Sometimes, an EXPLICIT type should be CONSTRUCTED. To do that, use +:constructed+
    # option:
    #  ptype = RASN2::Types::Integer.new(explicit: 2, class: :private, constructed: true)
    #
    # Implicit tagged values may also be defined:
    #  ctype_implicit = RASN2::Types::Integer.new(implicit: 0)
    # @author Sylvain Daubert
    class Base # rubocop:disable Metrics/ClassLength
      ID = nil

      attr_accessor :model

      # Allowed ASN.1 classes
      CLASSES = {
        universal: 0x00,
        application: 0x40,
        context: 0x80,
        private: 0xc0
      }.freeze

      def colorize(msg)
        tracer ? tracer.colorize(msg) : self.colorizer.wrap(msg)
      end

      include RASN2::Helpers::Colorize

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
      # @return [Hash[Symbol, Object]]
      attr_reader :options
      # @return [String] raw parsed data
      attr_reader :raw_data
      # @return [String] raw parsed length
      attr_reader :raw_length

      private :raw_data, :raw_length

      def tracer
        ::RASN2.tracer
      end

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
      # @return [Base]
      # @option options [Boolean] :ber if +true+, parse a BER string, else a DER one
      # @note More options are supported. See {Base#initialize}.
      def self.parse(der_or_ber, options={})
        obj = self.new(options)
        obj.parse!(der_or_ber, ber: options[:ber])
        obj
      end

      # Say if a type is constrained.
      # Always return +false+ for predefined types
      # @return [Booleran]
      def self.constrained?
        false
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
        set_value(options.delete(:value))
        self.options = options
        specific_initializer
        @raw_data = ''.b
        @raw_length = ''.b
      end

      # @abstract To help subclass initialize itself. Default implementation do nothing.
      def specific_initializer; end

      # Deep copy @value and @default.
      def initialize_copy(*)
        super
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

      # Say if this type is optional
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
        defined?(@tag) ? @tag == :explicit : nil # rubocop:disable Style/ReturnNilInPredicateMethodDefinition
      end

      # Say if a tagged type is implicit
      # @return [::Boolean,nil] return +nil+ if not tagged, return +true+
      #   if implicit, else +false+
      def implicit?
        defined?(@tag) ? @tag == :implicit : nil # rubocop:disable Style/ReturnNilInPredicateMethodDefinition
      end

      def private?
        self.instance_of?(Types::Tag)
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
        total_length, data = do_parse(der, ber: ber)
        return 0 if total_length.zero?

        if explicit?
          do_parse_explicit(data)
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

      def attributes
        attributes = []
        attributes << 'OPTIONAL' if optional?
        attributes << 'CONSTRUCTED' if constructed? && !(self.class < Constructed)
        attributes << 'EXPLICIT' if explicit?
        attributes << 'IMPLICIT' if implicit?
        attributes
      end

      # @param [Integer] level
      # @return [String]
      def inspect(level=0, color: false)
        lines = []
        new_level = level.abs + 1

        begin_colorizer(color)

        if constructed?
          lines << common_inspect(level, color: color)
          case @value
          when Array
            @value.each do |value|
              lines << if value.is_a?(Base)
                         value.inspect(new_level, color: color)
                       else
                         "#{'  ' * new_level}#{value.inspect}"
                       end
            end
          when Base
            lines << "#{'  ' * new_level}#{@value.inspect(new_level, color: color)}"
          else
            lines << "#{'  ' * new_level}#{@value.inspect}"
          end
        else
          lines << if inspect_value.empty?
                     common_inspect(level, color: color).to_s
                   else
                     "#{common_inspect(level, color: color)}: #{inspect_value}"
                   end
        end
        end_colorizer
        lines.reject(&:empty?).join("\n")
      end

      # Objects are equal if they have same class AND same DER
      # @param [Base] other
      # @return [Boolean]
      def ==(other)
        (other.class == self.class) && (other.to_der == self.to_der)
      end

      # Set options to this object
      # @param [Hash] options
      # @return [void]
      # @since 0.12
      def options=(options)
        set_class options[:class]
        set_optional options[:optional]
        set_default options[:default]
        set_tag options
        @name = options[:name]
        @options = options
      end

      # Say if a value is set
      # @return [Boolean]
      # @since 0.12.0
      def value?
        !@no_value
      end

      # Say if DER can be built (not default value, not optional without value, has a value)
      # @return [Boolean]
      # @since 0.12.0
      def can_build?
        value? && (@default.nil? || (@value != @default))
      end

      # @private Tracer private API
      # @return [String]
      def trace
        return trace_real if value?

        parts = [msg_type]
        parts << if default.nil?
                   colorize_nil
                 else
                   colorize_default(value)
                 end

        parts.reject(&:empty?).join(' ')
      end

      # @private Parse tage and length from binary string. Return data length and binary data.
      # @param [String] der
      # @param [Boolean] ber
      # @return [Array(::Integer, String)]
      # @since 0.15.0 was private before
      def do_parse(der, ber: false)
        return [0, ''] unless check_id(der)

        id_size = Types.decode_identifier_octets(der).last
        total_length, data = get_data(der[id_size..], ber)
        total_length += id_size
        @no_value = false

        [total_length, data]
      end

      # @private Delegate to #explicit type to generate sub-value
      # @param [String] data
      # @return [void]
      # @since 0.15.0 was private before
      def do_parse_explicit(data)
        type = explicit_type
        type.parse!(data)
        @value = type.value
      end

      # Make value from DER/BER string
      # @param [String] der
      # @param [::Boolean] ber
      # @return [void]
      # @since 0.15.0 was private before
      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        @value = der
      end

      def trace_real
        raw_id = encode_identifier_octets
        encoded_id = raw_id.unpack1('w*')
        data_length = raw_data.length
        encoded_length = raw_length.unpack1('w*')
        parts = [msg_type(raw_id.unpack1('H*').to_i(16), encoded_id)]
        msg = parts.reject(&:empty?).join(' ')
        msg << ", #{length_specifier(data_length, encoded_length)}"
        msg << trace_data
      end

      def trace_data(data=nil)
        data ||= raw_data
        format_string = data.size > 65_535 ? '%08X' : '%04X'
        lines = data.bytes.each_slice(16).map.with_index do |chunk, index|
          offset = format_string % (index * 16)
          hex = chunk.map { |b| '%02x' % b }.join(' ')
          hex_padded = hex.ljust(47) # 16*2 hex digits + 15 spaces
          ascii = chunk.map { |b| (32..126).cover?(b) ? b.chr : '.' }.join
          "  #{offset}  #{hex_padded}  |#{ascii}|"
        end
        "\n#{lines.join("\n")}"
      end

      def unpack(binstr)
        binstr.unpack1('H*')
      end

      def asn1_class_to_s
        asn1_class.to_s.upcase
      end

      def msg_type(raw_id=nil, _encoded_id=nil, no_id: false)
        parts = []
        parts << colorize_name(name) unless name.nil?
        real_id = no_id ? nil : raw_id || id
        parts << colorize_id(id, asn1_class_to_s) if real_id
        parts << colorize_class(type, real_id, *self.attributes)
        parts.reject(&:empty?).join(' ')
      end

      def pc_bit
        if @constructed.nil? && self.class.const_defined?(:ASN1_PC)
          self.class.const_get(:ASN1_PC)
        elsif @constructed # true
          Constructed::ASN1_PC
        else # false
          Primitive::ASN1_PC
        end
      end

      def universal?
        @asn1_class == :universal
      end

      def common_inspect(level=0, color: false)
        begin_colorizer(color)
        parts = []
        parts << "(#{model})" if model
        parts << colorize_name(name) if name
        parts << colorize_id(id, asn1_class_to_s) if id && !universal?
        class_name = colorize_class(type, nil, *self.attributes)
        class_name += ':' if constructed?
        parts << class_name
        end_colorizer
        ('  ' * level).to_s + parts.reject(&:empty?).join(' ').to_s
      end

      def inspect_value
        str = if value?
                colorize_value(value.inspect)
              else
                colorize_nil('(NO VALUE)')
              end

        str += colorize_default(@default) if @default
        str
      end

      def value_to_der
        case @value
        when Base
          @value.to_der
        else
          @value.to_s
        end
      end

      def set_class(asn1_class) # rubocop:disable Naming/AccessorMethodName
        case asn1_class
        when nil
          @asn1_class = :universal
        when Symbol
          raise ClassError unless CLASSES.key?(asn1_class)

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
      # {RASN2.parse} to parse non-universal class tags.
      def set_tag(options) # rubocop:disable Naming/AccessorMethodName
        @constructed = options[:constructed]
        if options[:explicit]
          @tag = :explicit
          @id_value = tag_id_to_integer(options[:explicit])
        elsif options[:implicit]
          @tag = :implicit
          @id_value = tag_id_to_integer(options[:implicit])
        elsif options[:tag_value]
          @id_value = tag_id_to_integer(options[:tag_value])
        end

        @asn1_class = :context if defined?(@tag) && (@asn1_class == :universal)
      end

      # Convert a tag id to an integer.
      # If given a String or Symbol, interprets the characters as big-endian octets
      # (like Apple 4-character codes / 4CCs). Integers are returned as-is.
      # @param [::Integer, String, Symbol] value tag value
      # @return [::Integer]
      def tag_id_to_integer(value)
        case value
        when ::Integer
          value
        when ::String, ::Symbol
          value.to_s.bytes.reduce(0) { |acc, b| (acc << 8) | b }
        else
          value
        end
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
        return @id_value if defined?(@id_value) && !@id_value.nil?

        self.class.const_get(:ID)
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

      # Check ID from +der+ is the one expected
      # @return [Boolean] +true+ is ID is expected, +false+ if it is not but +self+ is {#optional?}
      #   or has a {#default} value.
      # @raise [ASN1Error] ID was not expected, is not optional and has no default value
      def check_id(der) # rubocop:disable Naming/PredicateMethod
        expected_id = encode_identifier_octets
        real_id = der[0, expected_id.size]
        return true if real_id == expected_id

        if optional?
          @no_value = true
          @value = void_value
        elsif !@default.nil?
          @value = @default
        else
          return true if self.instance_of?(Tag)

          raise_id_error(der)
        end
        false
      end

      def get_data(der, ber)
        return [0, ''] if der.nil? || der.empty?

        length, length_length = get_length(der, ber)

        data = der[1 + length_length, length]
        @raw_length = der[0, length_length + 1]
        @raw_data = data

        total_length = 1 + length
        total_length += length_length if length_length.positive?

        [total_length, data]
      end

      def get_length(der, ber)
        length = der.unpack1('C').to_i
        length_length = 0

        if length == INDEFINITE_LENGTH
          raise_on_indefinite_length(ber)
        elsif length > INDEFINITE_LENGTH
          length_length = length & 0x7f
          length = der[1, length_length].unpack('C*')
                                        .reduce(0) { |len, b| (len << 8) | b }
        end

        [length, length_length]
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
        self.class.new(name: name)
      end

      def raise_id_error(der)
        msg = name.nil? ? +'' : "#{name}: "
        msg << "Expected #{self2name} but got #{der2name(der)}"

        raise ASN1Error, msg
      end

      def self2name
        parts = [asn1_class.to_s.upcase]
        parts << (constructed? ? 'CONSTRUCTED' : 'PRIMITIVE').to_s
        parts << if implicit? || explicit?
                   '0x%X (0x%s)' % [id, bin2hex(encode_identifier_octets)]
                 else
                   self.class.type.to_s
                 end
        parts.reject(&:empty?).join(' ')
      end

      def indent(input, by=2)
        input.split("\n").map { |line| ('  ' * by) + line }.join("\n")
      end

      def der2name(der)
        return 'no ID' if der.nil? || der.empty?

        asn1_class, pc, id, id_size = Types.decode_identifier_octets(der)
        name = "#{asn1_class.to_s.upcase} #{pc.to_s.upcase}"
        type =  find_type(id)
        name << " #{type.nil? ? bin2hex(der[0...id_size]).to_s : type.encoded_type}"
      end

      def find_type(id)
        Types.constants.map { |c| Types.const_get(c) }
             .grep(Class)
             .select { |klass| klass < Primitive || klass < Constructed }
             .find { |klass| id == klass::ID }
      end

      def bin2hex(str)
        str.unpack1('H*')
      end
    end
  end
end
