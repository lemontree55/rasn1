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
  # In a model, each element must have a unique name.
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
  # @author adfoster-r7 ModelValidationError, track source location for dynamic class methods
  class Model # rubocop:disable Metrics/ClassLength
    # @private Base Element
    BaseElem = Struct.new(:name, :proc, :content) do
      # @param [String,Symbol] name
      # @param [Proc] proc
      # @param [Array,nil] content
      def initialize(name, proc, content)
        check_duplicates(content.map(&:name) + [name]) unless content.nil?
        super
      end

      private

      # @return [Array<String>] The duplicate names found in the array
      def find_all_duplicate_names(names)
        names.group_by { |name| name }
             .select { |_name, values| values.length > 1 }
             .keys
      end

      def check_duplicates(names)
        duplicates = find_all_duplicate_names(names)
        raise ModelValidationError, "Duplicate name #{duplicates.first} found" if duplicates.any?
      end
    end

    # @private Model Element
    ModelElem = Struct.new(:name, :klass)

    # @private Wrapper Element
    WrapElem = Struct.new(:element, :options) do
      # @return [Symbol]
      def name
        :"#{element.name}_wrapper"
      end
    end

    # @private Sequence types
    SEQUENCE_TYPES = [Types::Sequence, Types::SequenceOf, Types::Set, Types::SetOf].freeze

    # Define helper methods to define models
    module Accel
      # @return [Hash]
      attr_reader :options

      # Use another model in this model
      # @param [String,Symbol] name
      # @param [Class] model_klass
      # @return [Elem]
      def model(name, model_klass)
        @root = ModelElem.new(name, model_klass)
      end

      # Use a {Wrapper} around a {Types::Base} or a {Model} object
      # @param [Types::Base,Model] element
      # @param [Hash] options
      # @return [WrapElem]
      # @since 0.12
      def wrapper(element, options={})
        @root = WrapElem.new(element, options)
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
      # @since 0.12.0 may change name through +:name+
      def root_options(options)
        @options = options
        return unless options.key?(:name)

        @root = @root.dup
        @root.name = options[:name]
      end

      # On inheritance, create +@root+ class variable
      # @param [Class] klass
      # @return [void]
      def inherited(klass)
        super
        root = @root
        klass.class_eval { @root = root }
      end

      # @private
      # @param [String,Symbol] accel_name
      # @param [Class] klass
      # @since 0.11.0
      # @since 0.12.0 track source location on error (adfoster-r7)
      def define_type_accel_base(accel_name, klass)
        singleton_class.class_eval <<-EVAL, __FILE__, __LINE__ + 1
          def #{accel_name}(name, options={}) # def sequence(name, type, options)
            options[:name] = name
            proc = proc do |opts|
              #{klass}.new(options.merge(opts)) # Sequence.new(options.merge(opts))
            end
            @root = BaseElem.new(name, proc, options[:content])
          end
        EVAL
      end

      # @private
      # @param [String,Symbol] accel_name
      # @param [Class] klass
      # @since 0.11.0
      # @since 0.12.0 track source location on error (adfoster-r7)
      def define_type_accel_of(accel_name, klass)
        singleton_class.class_eval <<-EVAL, __FILE__, __LINE__ + 1
          def #{accel_name}_of(name, type, options={}) # def sequence_of(name, type, options)
            options[:name] = name
            proc = proc do |opts|
              #{klass}.new(type, options.merge(opts)) # SequenceOf.new(type, options.merge(opts))
            end
            @root = BaseElem.new(name, proc, nil)
          end
        EVAL
      end

      # Define an accelarator to access a type in a model definition
      # @param [String] accel_name
      # @param [Class] klass class to instanciate
      # @since 0.11.0
      # @since 0.12.0 track source location on error (adfoster-r7)
      def define_type_accel(accel_name, klass)
        if klass < Types::SequenceOf
          define_type_accel_of(accel_name, klass)
        else
          define_type_accel_base(accel_name, klass)
        end
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
        @root = BaseElem.new(name, proc, nil)
      end

      # @param [Symbol,String] name name of object in model
      # @param [Hash] options
      # @return [Elem]
      # @see Types::Any#initialize
      def any(name, options={})
        options[:name] = name
        proc = proc { |opts| Types::Any.new(options.merge(opts)) }
        @root = BaseElem.new(name, proc, nil)
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

    extend Accel

    # @!method sequence(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Sequence#initialize
    # @!method set(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Set#initialize
    # @!method choice(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Choice#initialize
    %w[sequence set choice].each do |type|
      self.define_type_accel_base(type, Types.const_get(type.capitalize))
    end

    # @!method sequence_of(name, type, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Model, Types::Base] type type for SEQUENCE OF
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::SequenceOf#initialize
    # @!method set_of(name, type, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Model, Types::Base] type type for SET OF
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::SetOf#initialize
    %w[sequence set].each do |type|
      define_type_accel_of(type, Types.const_get(:"#{type.capitalize}Of"))
    end

    # @!method boolean(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Boolean#initialize
    # @!method integer(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Integer#initialize
    # @!method bit_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::BitString#initialize
    # @!method bmp_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::BmpString#initialize
    # @!method octet_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::OctetString#initialize
    # @!method null(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Null#initialize
    # @!method enumerated(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Enumerated#initialize
    # @!method universal_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::UniversalString#initialize
    # @!method utf8_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::Utf8String#initialize
    # @!method numeric_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::NumericString#initialize
    # @!method printable_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::PrintableString#initialize
    # @!method visible_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::VisibleString#initialize
    # @!method ia5_string(name, options)
    #  @!scope class
    #  @param [Symbol,String] name name of object in model
    #  @param [Hash] options
    #  @return [Elem]
    #  @see Types::IA5String#initialize
    Types.primitives.each do |prim|
      next if prim == Types::ObjectId

      method_name = prim.type.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase.gsub(/\s+/, '_')
      self.define_type_accel_base(method_name, prim)
    end

    # @return [Model, Wrapper, Types::Base]
    attr_reader :root

    # Create a new instance of a {Model}
    # @param [Hash] args
    def initialize(args={})
      @elements = {}
      generate_root(args)
      lazy_initialize(args) unless args.empty?
    end

    # @overload [](name)
    #  Access an element of the model by its name
    #  @param [Symbol] name
    #  @return [Model, Types::Base, Wrapper]
    # @overload [](idx)
    #  Access an element of root element by its index. Root element must be a {Sequence} or {SequenceOf}.
    #  @param [Integer] idx
    #  @return [Model, Types::Base, Wrapper]
    def [](name_or_idx)
      case name_or_idx
      when Symbol
        elt = @elements[name_or_idx]
        return elt unless elt.is_a?(Proc)

        @elements[name_or_idx] = elt.call
      when Integer
        root[name_or_idx]
      end
    end

    # Set value of element +name+. Element should be a {Types::Base}.
    # @param [String,Symbol] name
    # @param [Object] value
    # @return [Object] value
    def []=(name, value)
      # Here, use #[] to force generation for lazy elements
      raise Error, 'cannot set value for a Model' if self[name].is_a?(Model)

      self[name].value = value
    end

    # clone @elements and initialize @root from this new @element.
    def initialize_copy(_other)
      @elements = @elements.clone
      @root = @elements[@root_name]
    end

    # Give model name (a.k.a root name)
    # @return [String]
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
    # @param [String] der
    # @param [Boolean] ber accept BER encoding or not
    # @return [Integer] number of parsed bytes
    # @raise [ASN1Error] error on parsing
    def parse!(der, ber: false)
      root.parse!(der, ber: ber)
    end

    # @private
    # @see Types::Base#do_parse
    def do_parse(der, ber: false)
      root.do_parse(der, ber: ber)
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
        return nil if elt.nil?

        unless args.empty?
          args.each do |arg|
            elt = elt.root if elt.is_a?(Model)
            elt = elt[arg]
          end
        end

        elt.value
      end
    end

    # Return a hash image of model
    # @return [Hash]
    # Delegate some methods to root element
    # @param [Symbol] meth
    def method_missing(meth, *args, **kwargs)
      if root.respond_to?(meth)
        root.send(meth, *args, **kwargs)
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
      "#{'  ' * level}(#{type}) #{root.inspect(-level)}"
    end

    # Objects are equal if they have same class AND same DER
    # @param [Base] other
    # @return [Boolean]
    def ==(other)
      (other.class == self.class) && (other.to_der == self.to_der)
    end

    protected

    # Initialize model elements from +args+
    # @param [Hash,Array] args
    # @return [void]
    def lazy_initialize(args)
      case args
      when Hash
        lazy_initialize_hash(args)
      when Array
        lazy_initialize_array(args)
      end
    end

    # Initialize an element from a hash
    # @param [Hash] args
    # @return [void]
    def lazy_initialize_hash(args)
      args.each do |name, value|
        element = self[name]
        case element
        when Model
          element.lazy_initialize(value)
        when nil
        else
          element.value = value
        end
      end
    end

    # Initialize an sequence element from an array
    # @param [Array] args
    # @return [void]
    def lazy_initialize_array(ary)
      raise Error, 'Only sequence types may be initialized with an array' unless SEQUENCE_TYPES.any? { |klass| root.is_a?(klass) }

      ary.each do |initializer|
        root << initializer
      end
    end

    # Give a (nested) element from its name
    # @param [String, Symbol] name
    # @return [Model, Types::Base, nil]
    def by_name(name)
      elt = self[name]
      return elt unless elt.nil?

      @elements.each_value do |subelt|
        next unless subelt.is_a?(Model)

        value = subelt.by_name(name)
        return value unless value.nil?
      end

      nil
    end

    private

    def generate_root(args)
      opts = args.slice(:name, :explicit, :implicit, :optional, :class, :default, :constructed, :tag_value)
      root = self.class.class_eval { @root }
      root_options = self.class.options || {}
      root_options.merge!(opts)
      @root_name = args[:name] || root.name
      @root = generate_element(root, root_options)
      @elements[@root_name] = @root
    end

    def generate_element(elt, opts={})
      case elt
      when BaseElem
        generate_base_element(elt, opts)
      when ModelElem
        opts[:name] ||= elt.name
        elt.klass.new(opts)
      when WrapElem
        generate_wrapper_element(elt, opts)
      end
    end

    def generate_wrapper_element(elt, opts)
      wrapped = elt.element.is_a?(ModelElem) ? elt.element.klass : generate_element(elt.element)
      options = elt.options.merge(opts)
      options[:name] = elt.element.name if elt.element.is_a?(ModelElem)
      wrapper = Wrapper.new(wrapped, options)
      # Use a proc as wrapper may be lazy
      @elements[elt.element.name] = proc { wrapper.element }
      wrapper
    end

    def generate_base_element(elt, opts)
      element = elt.proc.call(opts)
      return element if elt.content.nil?

      element.value = elt.content.map do |subel|
        generated = generate_element(subel)
        @elements[subel.name] = generated
      end
      element
    end

    # @author sdaubert
    # @author lemontree55
    # @author adfoster-r7
    def private_to_h(element=nil) # rubocop:disable Metrics/CyclomaticComplexity
      my_element = element || root
      value = case my_element
              when Model
                model_to_h(my_element)
              when Types::SequenceOf
                sequence_of_to_h(my_element)
              when Types::Sequence
                sequence_to_h(my_element)
              when Types::Choice
                choice_to_h(my_element)
              when Wrapper
                wrapper_to_h(my_element)
              else
                my_element.value
              end
      if element.nil?
        { @root_name => value }
      else
        value
      end
    end

    def model_to_h(elt)
      hsh = elt.to_h
      if root.is_a?(Types::Choice)
        hsh[hsh.keys.first]
      else
        { @elements.key(elt) => hsh[hsh.keys.first] }
      end
    end

    def sequence_of_to_h(elt)
      if elt.of_type < Model
        elt.value&.map { |el| el.to_h.values.first }
      else
        elt.value&.map { |el| private_to_h(el) }
      end
    end

    def sequence_to_h(seq)
      ary = seq.value&.map do |el|
        next if el.optional? && el.value.nil?

        case el
        when Model
          model_to_h(el).to_a[0]
        when Wrapper
          [unwrap_keyname(@elements.key(el)), wrapper_to_h(el)]
        else
          [el.name, private_to_h(el)]
        end
      end
      ary.compact.to_h
    end

    def choice_to_h(elt)
      raise ChoiceError.new(elt) if elt.chosen.nil?

      chosen = elt.value[elt.chosen]
      { chosen.name => private_to_h(chosen) }
    end

    def unwrap_keyname(key)
      key.to_s.delete_suffix('_wrapper').to_sym
    end

    def wrapper_to_h(wrap)
      el = wrap.element
      case el
      when Model
        hsh = el.to_h
        hsh[hsh.keys.first]
      else
        private_to_h(el)
      end
    end
  end
end
