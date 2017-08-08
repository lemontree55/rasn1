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
    #  seqof = RASN1::Types::SequenceOf.new(:record, RASN1::Types::Integer)
    #  # Set integer values
    #  seqof.value = [1, 2, 3, 4]
    #
    # == Use with {Constructed} types
    # SEQUENCE OF may be used to create sequence of composed types. For example:
    #  composed_type = RASN1::Sequence.new(:comp)
    #  commposed_type.value = [RASN1::Types::Integer(:id),
    #                          RASN1::Types::OctetString(:data)]
    #  seqof = RASN1::SequenceOf.new(:comp, composed_type)
    #  seqof.value << [0, 'data0']
    #  seqof.value << [1, 'data1']
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
    #  seqof.value << { bool: true, int: 12 }
    #  seqof.value << { bool: false, int: 65535 }
    #  # Generate DER string
    #  der = seqof.to_der    # => String
    #  # parse 
    #  seqof.parse! der
    # @author Sylvain Daubert
    class SequenceOf < Constructed
      TAG = Sequence::TAG

      # @return [Class, Base]
      attr_reader :type

      # @param [Symbol, String] name name for this tag in grammar
      # @param [Class, Base] type base type for sequence of
      # @see Base#initialize
      def initialize(name, type, options={})
        super(name, options)
        @type = type
        @value = []
      end

      private

      def type_class
        type.is_a?(Class) ? type : type.class
      end

      def composed_type?
        [Sequence, Set].include? type_class
      end

      def value_to_der
        if composed_type?
          @value.map do |ary|
            s = type_class.new(@type.name)
            sval = []
            @type.value.each_with_index do |type, i|
              type2 = type.dup
              type2.value = ary[i]
              sval << type2
            end
            s.value = sval
            s.to_der
          end.join
        elsif type_class < Model
          @value.map do |hsh|
            model = type_class.new(hsh)
            model.to_der
          end.join
        else
          @value.map { |v| type_class.new(:t, value: v).to_der }.join
        end
      end

      def der_to_value(der, ber:false)
        @value = []
        nb_bytes = 0

        while nb_bytes < der.length
          of_type = if composed_type?
                      type.dup
                    elsif type_class < Model
                      type_class.new
                    else
                      type_class.new(:t)
                    end
          nb_bytes += of_type.parse!(der[nb_bytes, der.length])
          value = if composed_type?
                    of_type.value.map { |obj| obj.value }
                  elsif type_class < Model
                    of_type.to_h[of_type.to_h.keys.first]
                  else
                    of_type.value
                  end
          @value << value
        end
      end
    end
  end
end

