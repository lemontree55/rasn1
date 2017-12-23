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
      TAG = Sequence::TAG

      # @return [Class, Base]
      attr_reader :of_type

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
        @value = @value.map { |v| v.dup }
      end

      # Add an item to SEQUENCE OF
      # @param [Array,Hash, Model]
      def <<(obj)
        if of_type_class < Primitive
          raise ASN1Error, 'object to add should be an Array' unless obj.is_a?(Array)
          @value += obj.map { |item| @of_type.new(item) }
        elsif composed_of_type?
          raise ASN1Error, 'object to add should be an Array' unless obj.is_a?(Array)
          new_value = of_type_class.new
          @of_type.value.each_with_index do |type, i|
            type2 = type.dup
            type2.value = obj[i]
            new_value.value << type2
          end
          @value << new_value
        elsif of_type_class < Model
          case obj
          when Hash
            @value << @of_type.new(obj)
          when of_type_class
            @value << obj
          else
            raise ASN1Error, "object to add should be a #{of_type_class} or a Hash"
          end
        end
      end

      # Get element of index +idx+
      # @param [Integer] idx
      # @return [Base]
      def [](idx)
        @value[idx]
      end

      def inspect(level=0)
        str = ''
        str << '  ' * level if level > 0
        level = level.abs
        str << "#{type}:\n"
        level += 1
        @value.each do |item|
          case item
          when Base, Model
            next if item.optional? and item.value.nil?
            str << '  ' * level + "#{item.inspect(level)}"
            str << "\n" unless item.is_a?(Model)
          when Hash
            type = of_type_class.new(item)
            str << '  ' * level + "#{type.inspect(level)}"
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
        [Sequence, Set].include? of_type_class
      end

      def value_to_der
        @value.map { |v| v.to_der }.join
      end

      def der_to_value(der, ber:false)
        @value = []
        nb_bytes = 0

        while nb_bytes < der.length
          type = if composed_of_type?
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
    end
  end
end
