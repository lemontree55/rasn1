# frozen_string_literal: true

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
  #
  # == Delegation
  # {Model} may delegate some methods to its root element. Thus, if root element
  # is, for example, a {Types::Choice}, model may delegate +#chosen+ and +#chosen_value+.
  #
  # All methods defined by root may be delegated by model, unless model also defines
  # this method.
  # @author Sylvain Daubert
  class Model
    class << self
      # @return [Hash]
      attr_reader :options

      # Use another model in this model
      # @param [String,Symbol] name
      # @param [Class] model_klass
      def model(name, model_klass)
        @root = [name, model_klass]
      end

      # Update options of root element.
      # May be used when subclassing.
      #  class Model1 < RASN1::Model
      #    sequence :seq, implicit: 0,
      #             content: [bool(:bool), integer(:int)]
      #  end
      #
      #  # same as Model1 but with implicit tag set to 1
      #  class Model2 < Model1
      #    root_options implicit: 1
      #  end
      # @param [Hash] options
      # @return [void]
      def root_options(options)
        @options = options
      end

      # On inheritance, create +@root+ class variable
      # @param [Class] klass
      # @return [void]
      def inherited(klass)
        super
        root = @root
        klass.class_eval { @root = root }
      end

      # @method sequence(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Sequence#initialize
      # @method set(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Set#initialize
      # @method choice(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Choice#initialize
      %w[sequence set choice].each do |type|
        class_eval "def #{type}(name, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    Types::#{type.capitalize}.new(options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = [name, proc]\n" \
                   "  @root << options[:content] unless options[:content].nil?\n" \
                   "  @root\n" \
                   'end'
      end

      # @method sequence_of(name, type, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Model, Types::Base] type type for SEQUENCE OF
      #  @param [Hash] options
      #  @see Types::SequenceOf#initialize
      # @method set_of(name, type, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Model, Types::Base] type type for SET OF
      #  @param [Hash] options
      #  @see Types::SetOf#initialize
      %w[sequence set].each do |type|
        klass_name = "Types::#{type.capitalize}Of"
        class_eval "def #{type}_of(name, type, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    #{klass_name}.new(type, options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = [name, proc]\n" \
                   'end'
      end

      # @method boolean(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Boolean#initialize
      # @method integer(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Integer#initialize
      # @method bit_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::BitString#initialize
      # @method octet_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::OctetString#initialize
      # @method null(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Null#initialize
      # @method enumerated(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Enumerated#initialize
      # @method utf8_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::Utf8String#initialize
      # @method numeric_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::NumericString#initialize
      # @method printable_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::PrintableString#initialize
      # @method visible_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::VisibleString#initialize
      # @method ia5_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @see Types::IA5String#initialize
      Types.primitives.each do |prim|
        next if prim == Types::ObjectId

        method_name = prim.type.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase.gsub(/\s+/, '_')
        class_eval "def #{method_name}(name, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    #{prim}.new(options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = [name, proc]\n" \
                   'end'
      end

      # @param [Symbol,String] name name of object in model
      # @param [Hash] options
      # @note This method is named +objectid+ and not +object_id+ to not override
      #   +Object#object_id+.
      # @see Types::ObjectId#initialize
      def objectid(name, options={})
        options.merge!(name: name)
        proc = proc { |opts| Types::ObjectId.new(options.merge(opts)) }
        @root = [name, proc]
      end

      # @param [Symbol,String] name name of object in model
      # @param [Hash] options
      # @see Types::Any#initialize
      def any(name, options={})
        options.merge!(name: name)
        proc = proc { |opts| Types::Any.new(options.merge(opts)) }
        @root = [name, proc]
      end

      # Give type name (aka class name)
      # @return [String]
      def type
        return @type if defined? @type

        @type = self.to_s.gsub(/.*::/, '')
      end

      # Parse a DER/BER encoded string
      # @param [String] str
      # @param [Boolean] ber accept BER encoding or not
      # @return [Model]
      # @raise [ASN1Error] error on parsing
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
      set_elements(*root)
      initialize_elements self, args
    end

    # Give access to element +name+ in model
    # @param [String,Symbol] name
    # @return [Types::Base]
    def [](name)
      @elements[name]
    end

    # Set value of element +name+. Element should be a {Base}.
    # @param [String,Symbol] name
    # @param [Object] value
    # @return [Object] value
    def []=(name, value)
      raise Error, 'cannot set value for a Model' if @elements[name].is_a? Model

      @elements[name].value = value
    end

    # Get name frm root type
    # @return [String,Symbol]
    def name
      @root
    end

    # Get elements names
    # @return [Array<Symbol,String>]
    def keys
      @elements.keys
    end

    # Return a hash image of model
    # @return [Hash]
    def to_h
      private_to_h
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

    # Give type name (aka class name)
    # @return [String]
    def type
      self.class.type
    end

    # Parse a DER/BER encoded string, and modify object in-place.
    # @param [String] str
    # @param [Boolean] ber accept BER encoding or not
    # @return [Integer] number of parsed bytes
    # @raise [ASN1Error] error on parsing
    def parse!(str, ber: false)
      @elements[@root].parse!(str.dup.force_encoding('BINARY'), ber: ber)
    end

    # Delegate some methods to root element
    # @param [Symbol] meth
    def method_missing(meth, *args)
      if @elements[@root].respond_to? meth
        @elements[@root].send meth, *args
      else
        super
      end
    end

    # @return [Boolean]
    def respond_to_missing?(meth, *)
      @elements[@root].respond_to?(meth) || super
    end

    # @return [String]
    def inspect(level=0)
      '  ' * level + "(#{type}) #{root.inspect(-level)}"
    end

    # Objects are equal if they have same class AND same DER
    # @param [Base] other
    # @return [Boolean]
    def ==(other)
      (other.class == self.class) && (other.to_der == self.to_der)
    end

    private

    def composed?(elt)
      [Types::Sequence, Types::Set].include? elt.class
    end

    def get_type(proc_or_class, options={})
      case proc_or_class
      when Proc
        proc_or_class.call(options)
      when Class
        proc_or_class.new
      end
    end

    def generate_root
      root = self.class.class_eval { @root }
      @root = root[0]
      @elements = {}
      @elements[@root] = get_type(root[1], self.class.options || {})
      root
    end

    def set_elements(name, _elt, content=nil)
      return unless content.is_a? Array

      @elements[name].value = content.map do |name2, proc_or_class, content2|
        subel = get_type(proc_or_class)
        @elements[name2] = subel
        if composed?(subel) && content2.is_a?(Array)
          set_elements(name2, proc_or_class, content2)
        end
        subel
      end
    end

    def initialize_elements(obj, args)
      args.each do |name, value|
        if obj[name]
          if value.is_a? Hash
            if obj[name].is_a? Model
              initialize_elements obj[name], value
            else
              raise ArgumentError, "element #{name}: may only pass a Hash for Model elements"
            end
          elsif value.is_a? Array
            composed = if obj[name].is_a? Model
                         obj[name].root
                       else
                         obj[name]
                       end
            if composed.of_type.is_a? Model
              value.each do |el|
                composed << initialize_elements(composed.of_type.class.new, el)
              end
            else
              value.each do |el|
                obj[name] << el
              end
            end
          else
            obj[name].value = value
          end
        end
      end
    end

    def private_to_h(element=nil)
      my_element = element
      my_element = root if my_element.nil?
      my_element = my_element.root if my_element.is_a?(Model)
      value = case my_element
              when Types::SequenceOf
                if my_element.of_type < Model
                  my_element.value.map { |el| el.to_h.values.first }
                else
                  my_element.value.map { |el| private_to_h(el) }
                end
              when Types::Sequence
                seq = my_element.value.map do |el|
                  next if el.optional? && el.value.nil?

                  name = el.is_a?(Model) ? @elements.key(el) : el.name
                  [name, private_to_h(el)]
                end
                seq.compact!
                Hash[seq]
              else
                my_element.value
              end
      if element.nil?
        { @root => value }
      else
        value
      end
    end
  end
end
