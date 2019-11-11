# frozen_string_literal: true

module RASN1
  module Types
    # @abstract This is base class for all ASN.1 types.
    #
    #   Subclasses SHOULD define:
    #   * a TAG constant defining ASN.1 tag number,
    #   * a private method {#value_to_der} converting its {#value} to DER,
    #   * a private method {#der_to_value} converting DER into {#value}.
    #
    # ==Define an optional value
    # An optional value may be defined using +:optional+ key from {#initialize}:
    #   Integer.new(:int, optional: true)
    # An optional value implies:
    # * while parsing, if decoded tag is not optional expected tag, no {ASN1Error}
    #   is raised, and parser tries net tag,
    # * while encoding, if {#value} is +nil+, this value is not encoded.
    # ==Define a default value
    # A default value may be defined using +:default+ key from {#initialize}:
    #  Integer.new(:int, default: 0)
    # A default value implies:
    # * while parsing, if decoded tag is not expected tag, no {ASN1Error} is raised
    #   and parser sets default value to this tag. Then parser tries nex tag,
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
    class Base
      # Allowed ASN.1 tag classes
      CLASSES = {
        universal:   0x00,
        application: 0x40,
        context:     0x80,
        private:     0xc0
      }.freeze

      # @private Types that cannot be dupped (Ruby <= 2.3)
      UNDUPPABLE_TYPES = [[NilClass, nil], [TrueClass, true], [FalseClass, false], [Integer, 0]].map do |klass, obj|
        begin
          obj.dup
          nil
        rescue => TypeError
          klass
        end
      end.compact.freeze

      # Binary mask to get class
      # @private
      CLASS_MASK = 0xc0

      # Maximum ASN.1 tag number
      MAX_TAG = 0x1e

      # Length value for indefinite length
      INDEFINITE_LENGTH = 0x80

      # @return [String,nil]
      attr_reader :name
      # @return [Symbol]
      attr_reader :asn1_class
      # @return [Object,nil] default value, if defined
      attr_reader :default
      # @return [Object]
      attr_writer :value

      # Get ASN.1 type
      # @return [String]
      def self.type
        return @type if defined? @type

        @type = self.to_s.gsub(/.*::/, '').gsub(/([a-z0-9])([A-Z])/, '\1 \2').upcase
      end

      # Get ASN.1 type used to encode this one
      # @return [String]
      def self.encode_type
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

      # @overload initialize(options={})
      #   @param [Hash] options
      #   @option options [Symbol] :class ASN.1 tag class. Default value is +:universal+.
      #    If +:explicit+ or +:implicit:+ is defined, default value is +:context+.
      #   @option options [::Boolean] :optional define this tag as optional. Default
      #     is +false+
      #   @option options [Object] :default default value for DEFAULT tag
      #   @option options [Object] :value value to set
      #   @option options [::Integer] :implicit define an IMPLICIT tagged type
      #   @option options [::Integer] :explicit define an EXPLICIT tagged type
      #   @option options [::Boolean] :constructed if +true+, set type as constructed.
      #    May only be used when +:explicit+ is defined, else it is discarded.
      #   @option options [::String] :name name for this node
      # @overload initialize(value, options={})
      #   @param [Object] value value to set for this ASN.1 object
      #   @param [Hash] options
      #   @option options [Symbol] :class ASN.1 tag class. Default value is +:universal+.
      #    If +:explicit+ or +:implicit:+ is defined, default value is +:context+.
      #   @option options [::Boolean] :optional define this tag as optional. Default
      #     is +false+
      #   @option options [Object] :default default value for DEFAULT tag
      #   @option options [::Integer] :implicit define an IMPLICIT tagged type
      #   @option options [::Integer] :explicit define an EXPLICIT tagged type
      #   @option options [::Boolean] :constructed if +true+, set type as constructed.
      #    May only be used when +:explicit+ is defined, else it is discarded.
      #   @option options [::String] :name name for this node
      def initialize(value_or_options={}, options={})
        @constructed = nil
        if value_or_options.is_a? Hash
          set_options value_or_options
        else
          set_options options
          @value = value_or_options
        end
      end

      # Used by +#dup+ and +#clone+. Deep copy @value and @default.
      def initialize_copy(_other)
        @value = @value.dup unless UNDUPPABLE_TYPES.include?(@value.class)
        @default = @default.dup unless UNDUPPABLE_TYPES.include?(@default.class)
      end

      # Get value or default value
      def value
        if @value.nil?
          @default
        else
          @value
        end
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
        !defined?(@tag) ? nil : @tag == :explicit
      end

      # Say if a tagged type is implicit
      # @return [::Boolean,nil] return +nil+ if not tagged, return +true+
      #   if implicit, else +false+
      def implicit?
        !defined?(@tag) ? nil : @tag == :implicit
      end

      # @abstract This method SHOULD be partly implemented by subclasses, which
      #   SHOULD respond to +#value_to_der+.
      # @return [String] DER-formated string
      def to_der
        build_tag
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

      # Get tag value
      # @return [Integer]
      def tag
        pc = if @constructed.nil?
               self.class::ASN1_PC
             elsif @constructed # true
               Constructed::ASN1_PC
             else # false
               0
             end
        tag_value | CLASSES[@asn1_class] | pc
      end

      # @abstract This method SHOULD be partly implemented by subclasses to parse
      #  data. Subclasses SHOULD respond to +#der_to_value+.
      # Parse a DER string. This method updates object.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      # @raise [ASN1Error] error on parsing
      def parse!(der, ber: false)
        return 0 unless check_tag(der)

        total_length, data = get_data(der, ber)
        if explicit?
          # Delegate to #explicit type to generate sub-tag
          type = explicit_type
          type.value = @value
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
        str << " #{value.inspect}"
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

      def common_inspect(level)
        lvl = level >= 0 ? level : 0
        str = '  ' * lvl
        str << "#{@name} " unless @name.nil?
        str << "#{type}:"
      end

      def value_to_der
        case @value
        when Base
          @value.to_der
        else
          @value.to_s
        end
      end

      def der_to_value(der, ber: false)
        @value = der
      end

      def set_options(options)
        set_class options[:class]
        set_optional options[:optional]
        set_default options[:default]
        set_tag options
        @value = options[:value]
        @name = options[:name]
      end

      def set_class(asn1_class)
        case asn1_class
        when nil
          @asn1_class = :universal
        when Symbol
          raise ClassError unless CLASSES.keys.include? asn1_class

          @asn1_class = asn1_class
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

      # handle undocumented option +:tag_value+, used internally by
      # {RASN1.parse} to parse non-universal class tags.
      def set_tag(options)
        if options[:explicit]
          @tag = :explicit
          @tag_value = options[:explicit]
          @constructed = options[:constructed]
        elsif options[:implicit]
          @tag = :implicit
          @tag_value = options[:implicit]
          @constructed = options[:constructed]
        elsif options[:tag_value]
          @tag_value = options[:tag_value]
          @constructed = options[:constructed]
        end

        @asn1_class = :context if defined?(@tag) && (@asn1_class == :universal)
      end

      def build_tag?
        !(!@default.nil? && (@value.nil? || (@value == @default))) &&
          !(optional? && @value.nil?)
      end

      def build_tag
        if build_tag?
          if explicit?
            v = explicit_type
            v.value = @value
            encoded_value = v.to_der
          else
            encoded_value = value_to_der
          end
          encode_tag << encode_size(encoded_value.size) << encoded_value
        else
          ''
        end
      end

      def tag_value
        return @tag_value if defined? @tag_value

        self.class::TAG
      end

      def encode_tag
        raise ASN1Error, 'multi-byte tag value are not supported' unless tag_value <= MAX_TAG

        [tag].pack('C')
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

      def check_tag(der)
        tag = der[0, 1]
        if tag != encode_tag
          if optional?
            @value = nil
          elsif !@default.nil?
            @value = @default
          else
            raise_tag_error(tag)
          end
          false
        else
          true
        end
      end

      def get_data(der, ber)
        length = der[1, 1].unpack('C').first
        length_length = 0

        if length == INDEFINITE_LENGTH
          if primitive?
            raise ASN1Error, "malformed #{type} TAG: indefinite length " \
              'forbidden for primitive types'
          elsif ber
            raise NotImplementedError, 'TAG: indefinite length not ' \
              'supported yet'
          else
            raise ASN1Error, 'TAG: indefinite length forbidden in DER ' \
              'encoding'
          end
        elsif length < INDEFINITE_LENGTH
          data = der[2, length]
        else
          length_length = length & 0x7f
          length = der[2, length_length].unpack('C*')
                                        .reduce(0) { |len, b| (len << 8) | b }
          data = der[2 + length_length, length]
        end

        total_length = 2 + length
        total_length += length_length if length_length.positive?

        [total_length, data]
      end

      def explicit_type
        self.class.new
      end

      def raise_tag_error(tag)
        msg = name.nil? ? +'' : +"#{name}: "
        msg << "Expected #{self2name} but get #{tag2name(tag)}"
        raise ASN1Error, msg
      end

      def class_from_numeric_tag(tag)
        CLASSES.key(tag & CLASS_MASK)
      end

      def self2name
        name = class_from_numeric_tag(tag).to_s.upcase
        name << " #{(tag & Constructed::ASN1_PC).positive? ? 'CONSTRUCTED' : 'PRIMITIVE'}"
        if implicit? || explicit?
          name << ' 0x%02X (0x%02X)' % [tag & 0x1f, tag]
        else
          name << ' ' << self.class.type
        end
      end

      def tag2name(tag)
        return 'no tag' if tag.nil? || tag.empty?

        itag = tag.unpack('C').first
        name = class_from_numeric_tag(itag).to_s.upcase
        name << " #{(itag & Constructed::ASN1_PC).positive? ? 'CONSTRUCTED' : 'PRIMITIVE'}"
        type =  Types.constants.map { |c| Types.const_get(c) }
                     .select { |klass| klass < Primitive || klass < Constructed }
                     .find { |klass| klass::TAG == itag & 0x1f }
        name << " #{type.nil? ? '0x%02X (0x%02X)' % [itag & 0x1f, itag] : type.encode_type}"
      end
    end
  end
end
