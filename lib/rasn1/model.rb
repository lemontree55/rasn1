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
  #                       Record])
  #  end
  # Set values like this:
  #  record2 = Record2.new
  #  record2[:rented] = true
  #  record2[:record][:id] = 65537
  #  record2[:record][:room] = 43
  # or like this:
  #  record2 = Record2.new(rented: true, record: { id: 65537, room: 43 })
  # @author Sylvain Daubert
  class Model

    class << self

      %w(sequence set).each do |type|
        class_eval "def #{type}(name, options={})\n" \
                   "  @records ||= {}\n" \
                   "  @records[name] = Proc.new do\n" \
                   "    t = Types::#{type.capitalize}.new(name, options)\n" \
                   "    t.value = options[:content] if options[:content]\n" \
                   "    t\n" \
                   "  end\n" \
                   "end"
      end

      # define all class methods to instance a ASN.1 TAG
      Types.primitives.each do |prim|
        class_eval "def #{prim.type.downcase.gsub(/\s+/, '_')}(name, options={})\n" \
                   "  Proc.new { #{prim.to_s}.new(name, options) }\n" \
                   "end"
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
      set_elements
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

    # Return a hash image of model
    # @return [Hash]
    def to_h
      { @root => private_to_h(@elements[@root]) }
    end

    # @return [String]
    def to_der
      @elements[@root].to_der
    end

    # Parse a DER/BER encoded string, and modify object in-place.
    # @param [String] str
    # @param [Boolean] ber accept BER encoding or not
    # @return [Integer] number of parsed bytes
    def parse!(str, ber: false)
      @elements[@root].parse!(str, ber: ber)
    end

    private

    def set_elements(element=nil)
      if element.nil?
        records = self.class.class_eval { @records }
        @root = records.keys.first
        @elements = {}
        @elements[@root] = records[@root].call
        if @elements[@root].value.is_a? Array
          @elements[@root].value = @elements[@root].value.map do |subel|
            se = case subel
                 when Proc
                   subel.call
                 when Class
                   subel.new
                 end
            @elements[se.name] = se
            set_elements se if se.is_a? Types::Sequence
            se
          end
        end
      else
        element.value.map! do |subel|
          se = case subel
               when Proc
                 subel.call
               when Class
                 subel.new
               end
          @elements[se.name] = se
          set_elements se if se.is_a? Types::Sequence
          se
        end
      end
    end

    def initialize_elements(obj, args)
      args.each do |name, value|
        if obj[name]
          if value.is_a? Hash
            if obj[name].is_a? Model
              initialize_elements obj[name], value
            else
              raise ArgumentError, "element #{name}: may only pass a Hash for Sequence elements"
            end
          else
            obj[name].value = value
          end
        end
      end
    end

    def private_to_h(element)
      h = {}
      element.value.each do |subel|
        h[subel.name] = case subel
                        when Types::Sequence
                          private_to_h(subel)
                        when Model
                          subel.to_h[subel.name]
                        else
                          next if subel.value.nil? and subel.optional?
                          subel.value
                        end
      end

      h
    end
  end
end
