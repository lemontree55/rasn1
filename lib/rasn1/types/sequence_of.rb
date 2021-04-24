# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 SEQUENCE OF
    #
    # A SEQUENCE OF is an array of one ASN.1 type.
    #
    # == Use with {Primitive} types
    # To encode this ASN.1 example:
    #  Integers ::= SEQUENCE OF INTEGER
    # do:
    #  # Create a SEQUENCE OF INTEGER
    #  seqof = RASN1::Types::SequenceOf.new(RASN1::Types::Integer)
    #  # Set integer values
    #  seqof.value = [1, 2, 3, 4]
    #
    # == Use with {Constructed} types
    # SEQUENCE OF may be used to create sequence of composed types. For example:
    #  composed_type = RASN1::Types::Sequence.new
    #  commposed_type.value = [RASN1::Types::Integer,
    #                          RASN1::Types::OctetString]
    #  seqof = RASN1::Types::SequenceOf.new(composed_type)
    #  seqof << [0, 'data0']
    #  seqof << [1, 'data1']
    #
    # == Use with {Model}
    # SEQUENCE OF may also be used with a Model type:
    #  class MyModel < RASN1::Model
    #    sequence :seq,
    #             content: [boolean(:bool), integer(:int)]
    #  end
    #
    #  seqof = RASN1::Types::SequenceOf.new(:record, MyModel)
    #  # set values
    #  seqof << { bool: true, int: 12 }
    #  seqof << { bool: false, int: 65535 }
    #  # Generate DER string
    #  der = seqof.to_der    # => String
    #  # parse
    #  seqof.parse! der
    #
    # After parsing, a SEQUENCE OF may be accessed as an Array:
    #  seqof[0]                # => MyModel
    #  seqof[0][:bool].value   # => true
    #  seqof[0][:int].value    # => 12
    # @author Sylvain Daubert
    class SequenceOf < Constructed
      # SequenceOf id value
      ID = Sequence::ID

      # @return [Class, Base]
      attr_reader :of_type

      # A SEQUENCE OF is encoded as a SEQUENCE.
      # @return ['SEQUENCE']
      def self.encoded_type
        Sequence.encoded_type
      end

      # @param [Symbol, String] name name for this tag in grammar
      # @param [Class, Base] of_type base type for sequence of
      # @see Base#initialize
      def initialize(of_type, options={})
        super(options)
        @of_type = of_type
        @value = []
      end

      def initialize_copy(other)
        super
        @of_type = @of_type.dup
        @value = @value.map(&:dup)
      end

      # Add an item to SEQUENCE OF
      # @param [Array,Hash, Model]
      def <<(obj)
        return push_array_of_primitive(obj) if of_type_class < Primitive
        return push_composed_array(obj) if composed_of_type?

        push_model(obj)
      end

      # Get element of index +idx+
      # @param [Integer] idx
      # @return [Base]
      def [](idx)
        @value[idx]
      end

      # Get length of SEQUENCE OF (ie number of elements)
      # @return [Integer]
      def length
        @value.length
      end

      def inspect(level=0)
        str = common_inspect(level)
        str << "\n"
        level = level.abs + 1
        @value.each do |item|
          case item
          when Base, Model
            next if item.optional? && item.value.nil?

            str << item.inspect(level)
            str << "\n" unless str.end_with?("\n")
          else
            str << '  ' * level + "#{item.inspect}\n"
          end
        end
        str
      end

      private

      def of_type_class
        @of_type.is_a?(Class) ? @of_type : @of_type.class
      end

      def composed_of_type?
        !@of_type.is_a?(Class) && [Sequence, Set].include?(of_type_class)
      end

      def value_to_der
        @value.map(&:to_der).join
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        @value = []
        nb_bytes = 0

        while nb_bytes < der.length
          type = if composed_of_type? && !@of_type.is_a?(Class)
                   @of_type.dup
                 elsif of_type_class < Model
                   of_type_class.new
                 else
                   of_type_class.new(:t)
                 end
          nb_bytes += type.parse!(der[nb_bytes, der.length])
          @value << type
        end
      end

      def explicit_type
        self.class.new(self.of_type)
      end

      def push_array_of_primitive(obj)
        raise ASN1Error, 'object to add should be an Array' unless obj.is_a?(Array)

        @value += obj.map { |item| of_type_class.new(item) }
      end

      def push_composed_array(obj)
        raise ASN1Error, 'object to add should be an Array' unless obj.is_a?(Array)

        new_value = of_type_class.new
        @of_type.value.each_with_index do |type, i|
          type2 = type.dup
          type2.value = obj[i]
          new_value.value << type2
        end
        @value << new_value
      end

      def push_model(obj)
        case obj
        when Hash
          @value << of_type_class.new(obj)
        when of_type_class
          @value << obj
        else
          raise ASN1Error, "object to add should be a #{of_type_class} or a Hash"
        end
      end
    end
  end
end
