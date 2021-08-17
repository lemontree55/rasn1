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
  class Model # rubocop:disable Metrics/ClassLength
    # @private
    Elem = Struct.new(:name, :proc_or_class, :content)

    class << self
      # @return [Hash]
      attr_reader :options

      # Use another model in this model
      # @param [String,Symbol] name
      # @param [Class] model_klass
      # @return [Elem]
      def model(name, model_klass)
        @root = Elem.new(name, model_klass, nil)
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
      #  @return [Elem]
      #  @see Types::Sequence#initialize
      # @method set(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Set#initialize
      # @method choice(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Choice#initialize
      %w[sequence set choice].each do |type|
        class_eval "def #{type}(name, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    Types::#{type.capitalize}.new(options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = Elem.new(name, proc, options[:content])\n" \
                   'end'
      end

      # @method sequence_of(name, type, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Model, Types::Base] type type for SEQUENCE OF
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::SequenceOf#initialize
      # @method set_of(name, type, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Model, Types::Base] type type for SET OF
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::SetOf#initialize
      %w[sequence set].each do |type|
        klass_name = "Types::#{type.capitalize}Of"
        class_eval "def #{type}_of(name, type, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    #{klass_name}.new(type, options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = Elem.new(name, proc, nil)\n" \
                   'end'
      end

      # @method boolean(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Boolean#initialize
      # @method integer(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Integer#initialize
      # @method bit_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::BitString#initialize
      # @method octet_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::OctetString#initialize
      # @method null(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Null#initialize
      # @method enumerated(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Enumerated#initialize
      # @method utf8_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::Utf8String#initialize
      # @method numeric_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::NumericString#initialize
      # @method printable_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::PrintableString#initialize
      # @method visible_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::VisibleString#initialize
      # @method ia5_string(name, options)
      #  @param [Symbol,String] name name of object in model
      #  @param [Hash] options
      #  @return [Elem]
      #  @see Types::IA5String#initialize
      Types.primitives.each do |prim|
        next if prim == Types::ObjectId

        method_name = prim.type.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase.gsub(/\s+/, '_')
        class_eval "def #{method_name}(name, options={})\n" \
                   "  options.merge!(name: name)\n" \
                   "  proc = proc do |opts|\n" \
                   "    #{prim}.new(options.merge(opts))\n" \
                   "  end\n" \
                   "  @root = Elem.new(name, proc, nil)\n" \
                   'end'
      end

      # @param [Symbol,String] name name of object in model
      # @param [Hash] options
      # @return [Elem]
      # @note This method is named +objectid+ and not +object_id+ to not override
      #   +Object#object_id+.
      # @see Types::ObjectId#initialize
      def objectid(name, options={})
        options[:name] = name
        proc = proc { |opts| Types::ObjectId.new(options.merge(opts)) }
        @root = Elem.new(name, proc, nil)
      end

      # @param [Symbol,String] name name of object in model
      # @param [Hash] options
      # @return [Elem]
      # @see Types::Any#initialize
      def any(name, options={})
        options[:name] = name
        proc = proc { |opts| Types::Any.new(options.merge(opts)) }
        @root = Elem.new(name, proc, nil)
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
        model.parse!(str, ber: ber)
        model
      end
    end

    # Create a new instance of a {Model}
    # @param [Hash] args
    def initialize(args={})
      root = generate_root
      set_elements(root)
      initialize_elements(self, args)
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

    # Get name from root type
    # @return [String,Symbol]
    def name
      @root_name
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

    # Get root element from model
    # @return [Types::Base,Model]
    def root
      @elements[@root_name]
    end

    # @return [String]
    def to_der
      root.to_der
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
      root.parse!(str.dup.force_encoding('BINARY'), ber: ber)
    end

    # @overload value
    #  Get value of root element
    #  @return [Object,nil]
    # @overload value(name, *args)
    #  Direct access to the value of +name+ (nested) element of model.
    #  @param [String,Symbol] name
    #  @param [Array<Integer,String,Symbol>] args more argument to access element. May be
    #     used to access content of a SequenceOf or a SetOf
    #  @return [Object,nil]
    # @return [Object,nil]
    # @example
    #  class MyModel1 < RASN1::Model
    #    sequence('seq', content: [boolean('boolean'), integer('int')])
    #  end
    #  class MyModel2 < RASN1::Model
    #    sequence('root', content: [sequence_of('list', MyModel1)])
    #  end
    #  model = MyModel2.new
    #  model.parse!(der)
    #  # access to 2nd MyModel1.int in list
    #  model.value('list', 1, 'int')
    def value(name=nil, *args)
      if name.nil?
        root.value
      else
        elt = by_name(name)

        unless args.empty?
          args.each do |arg|
            elt = elt.root if elt.is_a?(Model)
            elt = elt[arg]
          end
        end

        elt.value
      end
    end

    # Delegate some methods to root element
    # @param [Symbol] meth
    def method_missing(meth, *args)
      if root.respond_to? meth
        root.send meth, *args
      else
        super
      end
    end

    # @return [Boolean]
    def respond_to_missing?(meth, *)
      root.respond_to?(meth) || super
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

    protected

    # Give a (nested) element from its name
    # @param [String, Symbol] name
    # @return [Model, Types::Base, nil]
    def by_name(name)
      elt = self[name]
      return elt unless elt.nil?

      @elements.each_key do |subelt_name|
        if self[subelt_name].is_a?(Model)
          elt = self[subelt_name][name]
          return elt unless elt.nil?
        end
      end

      nil
    end

    private

    def composed?(elt)
      [Types::Sequence, Types::Set].include? elt.class
    end

    # proc_or_class:
    # * proc: a Types::Base subclass
    # * class: a model
    def get_type(proc_or_class, options={})
      case proc_or_class
      when Proc
        proc_or_class.call(options)
      when Class
        proc_or_class.new
      end
    end

    def generate_root
      class_element = self.class.class_eval { @root }
      @root_name = class_element.name
      @elements = {}
      @elements[@root_name] = get_type(class_element.proc_or_class, self.class.options || {})
      class_element
    end

    def set_elements(element) # rubocop:disable Naming/AccessorMethodName
      return unless element.content.is_a? Array

      @elements[name].value = element.content.map do |another_element|
        subel = get_type(another_element.proc_or_class)
        @elements[another_element.name] = subel
        set_elements(another_element) if composed?(subel) && another_element.content.is_a?(Array)
        subel
      end
    end

    def initialize_elements(obj, args)
      args.each do |name, value|
        next unless obj[name]

        case value
        when Hash
          raise ArgumentError, "element #{name}: may only pass a Hash for Model elements" unless obj[name].is_a? Model

          initialize_elements obj[name], value
        when Array
          initialize_element_from_array(obj[name], value)
        else
          obj[name].value = value
        end
      end
    end

    def initialize_element_from_array(obj, value)
      composed = obj.is_a?(Model) ? obj.root : obj
      if composed.of_type.is_a?(Model)
        value.each do |el|
          composed << initialize_elements(composed.of_type.class.new, el)
        end
      else
        value.each { |el| composed << el }
      end
    end

    def private_to_h(element=nil)
      my_element = element || root
      my_element = my_element.root if my_element.is_a?(Model)
      value = case my_element
              when Types::SequenceOf
                sequence_of_to_h(my_element)
              when Types::Sequence
                sequence_to_h(my_element)
              else
                my_element.value
              end
      if element.nil?
        { @root_name => value }
      else
        value
      end
    end

    def sequence_of_to_h(elt)
      if elt.of_type < Model
        elt.value.map { |el| el.to_h.values.first }
      else
        elt.value.map { |el| private_to_h(el) }
      end
    end

    def sequence_to_h(seq)
      ary = seq.value.map do |el|
        next if el.optional? && el.value.nil?

        name = el.is_a?(Model) ? @elements.key(el) : el.name
        [name, private_to_h(el)]
      end
      ary.compact!
      ary.to_h
    end
  end
end
