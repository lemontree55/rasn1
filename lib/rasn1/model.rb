module RASN1

  # @abstract
  # {Model} class is a base class to define ASN.1 models.
  # == Create a simple ASN.1 model
  # Given this ASN.1 example:
  #  Record ::= SEQUENCE {
  #    id        INTEGER,
  #    room  [0] IMPLICIT INTEGER OPTIONAL,
  #    house [1] EXPLICIT INTEGER DEFAULT 0
  #  }
  # you may create your model like this:
  #  class Record < RASN1::Model
  #    sequence(:record,
  #             content: [integer(:id),
  #                       integer(:room, implicit: 0, optional: true),
  #                       integer(:house, explicit: 1, default: 0)])
  #  end
  #
  # === Parse a DER-encoded string
  #  record = Record.parse(der_string)
  #  record[:id]             # => RASN1::Types::Integer
  #  record[:id].value       # => Integer
  #  record[:id].to_i        # => Integer
  #  record[:id].asn1_class  # => Symbol
  #  record[:id].optional?   # => false
  #  record[:id].default     # => nil
  #  record[:room].optional  # => true
  #  record[:house].default  # => 0
  #
  # You may also parse a BER-encoded string this way:
  #  record = Record.parse(der_string, ber: true)
  #
  # === Generate a DER-encoded string
  #  record = Record.new(id: 12, room: 24)
  #  record.to_der
  #
  # == Create a more complex model
  # Models may be nested. For example:
  #  class Record2 < RASN1::Model
  #    sequence(:record2,
  #             content: [boolean(:rented, default: false),
  #                       model(:a_record, Record)])
  #  end
  # Set values like this:
  #  record2 = Record2.new
  #  record2[:rented] = true
  #  record2[:a_record][:id] = 65537
  #  record2[:a_record][:room] = 43
  # or like this:
  #  record2 = Record2.new(rented: true, a_record: { id: 65537, room: 43 })
  # @author Sylvain Daubert
  class Model

    class << self

      # Use another model in this model
      # @param [String,Symbol] name
      # @param [Class] model_klass
      def model(name, model_klass)
        @root = [name, model_klass]
      end

      # @method sequence(name, options)
      #  @see Types::Sequence#initialize
      # @method set(name, options)
      #  @see Types::Set#initialize
      # @method choice(name, options)
      #  @see Types::Choice#initialize
      %w(sequence set choice).each do |type|
        class_eval "def #{type}(name, options={})\n" \
                   "  proc = Proc.new do\n" \
                   "    Types::#{type.capitalize}.new(name, options)\n" \
                   "  end\n" \
                   "  @root = [name, proc]\n" \
                   "  @root << options[:content] unless options[:content].nil?\n" \
                   "  @root\n" \
                   "end"
      end

      # @method sequence_of(name, type, options)
      #  @see Types::SequenceOf#initialize
      # @method set_of(name, type, options)
      #  @see Types::SetOf#initialize
      %w(sequence set).each do |type|
        klass_name = "Types::#{type.capitalize}Of"
        class_eval "def #{type}_of(name, type, options={})\n" \
                   "  proc = Proc.new do\n" \
                   "    #{klass_name}.new(name, type, options)\n" \
                   "  end\n" \
                   "  @root = [name, proc]\n" \
                   "end"
      end

      # @method boolean(name, options)
      #  @see Types::Boolean#initialize
      # @method integer(name, options)
      #  @see Types::Integer#initialize
      # @method bit_string(name, options)
      #  @see Types::BitString#initialize
      # @method octet_string(name, options)
      #  @see Types::OctetString#initialize
      # @method null(name, options)
      #  @see Types::Null#initialize
      # @method enumerated(name, options)
      #  @see Types::Enumerated#initialize
      # @method utf8_string(name, options)
      #  @see Types::Utf8String#initialize
      Types.primitives.each do |prim|
        next if prim == Types::ObjectId
        class_eval "def #{prim.type.downcase.gsub(/\s+/, '_')}(name, options={})\n" \
                   "  proc = Proc.new { #{prim.to_s}.new(name, options) }\n" \
                   "  @root = [name, proc]\n" \
                   "end"
      end

      # @note This method is named +objectid+ and not +object_id+ to not override
      #   +Object#object_id+.
      # @see Types::ObjectId#initialize
      def objectid(name, options={})
        proc = Proc.new { Types::ObjectId.new(name, options) }
        @root = [name, proc]
      end

      # @see Types::Any#initialize
      def any(name, options={})
        proc = Proc.new { Types::Any.new(name, options) }
        @root = [name, proc]
      end

      # Parse a DER/BER encoded string
      # @param [String] str
      # @param [Boolean] ber accept BER encoding or not
      # @return [Model]
      def parse(str, ber: false)
        model = new
        model.parse! str, ber: ber
        model
      end
    end

    # Create a new instance of a {Model}
    # @param [Hash] args
    def initialize(args={})
      root = generate_root
      set_elements *root
      initialize_elements self, args
    end

    # Give access to element +name+ in model
    # @param [String,Symbol] name
    # @return [Types::Base]
    def [](name)
      @elements[name]
    end

    # Get name frm root type
    # @return [String,Symbol]
    def name
      @elements[@root].name
    end

    # Get elements names
    # @return [Array<Symbol,String>]
    def keys
      @elements.keys
    end

    # Return a hash image of model
    # @return [Hash]
    def to_h
      { @root => private_to_h(@elements[@root]) }
    end

    # @return [String]
    def to_der
      @elements[@root].to_der
    end

    # Get root element from model
    # @return [Types::Base,Model]
    def root
      @elements[@root]
    end

    # Parse a DER/BER encoded string, and modify object in-place.
    # @param [String] str
    # @param [Boolean] ber accept BER encoding or not
    # @return [Integer] number of parsed bytes
    def parse!(str, ber: false)
      @elements[@root].parse!(str.dup.force_encoding('BINARY'), ber: ber)
    end

    private

    def is_composed?(el)
      [Types::Sequence, Types::Set].include? el.class
    end

    def is_of?(el)
      [Types::SequenceOf, Types::SetOf].include? el.class
    end

    def get_type(proc_or_class, name=nil)
      case proc_or_class
      when Proc
        proc_or_class.call
      when Class
        options = {}
        options[:root] = name unless name.nil?
        proc_or_class.new(options)
      end
    end

    def generate_root
      root = self.class.class_eval { @root }
      @root = root[0]
      @elements = {}
      @elements[@root] = get_type(root[1])
      root
    end

    def set_elements(name, el, content=nil)
      if content.is_a? Array
        @elements[name].value = content.map do |name2, proc_or_class, content2|
          subel = get_type(proc_or_class, name2)
          @elements[name2] = subel
          if is_composed?(subel) and content2.is_a? Array
            set_elements(name2, proc_or_class, content2)
          end
          subel
        end
      end
    end

    def initialize_elements(obj, args)
      if args[:root]
        rootname = args.delete(:root)
        @elements[rootname] = @elements.delete(@root)
        @elements[rootname].name = rootname
        @root = rootname
      end

      args.each do |name, value|
        if obj[name]
          if value.is_a? Hash
            if obj[name].is_a? Model
              initialize_elements obj[name], value
            else
              raise ArgumentError, "element #{name}: may only pass a Hash for Model elements"
            end
          else
            obj[name].value = value
          end
        end
      end
    end

    def private_to_h(element)
      if element.value.is_a? Array
        h = {}
        element.value.each do |subel|
          case subel
          when Types::Sequence, Types::Set
            h[subel.name] = private_to_h(subel)
          when Model
            h[subel.name] = subel.to_h[subel.name]
          when Hash
            # Array of Hash for SequenceOf and SetOf
            return element.value
          else
            next if subel.value.nil? and subel.optional?
            h[subel.name] = subel.value
          end
        end
        h
      else
        element.value
      end
    end
  end
end
