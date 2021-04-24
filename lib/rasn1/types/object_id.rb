# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Object ID
    # @author Sylvain Daubert
    class ObjectId < Primitive
      # ObjectId id value
      ID = 6

      private

      def value_to_der
        ids = @value.to_s.split('.').map!(&:to_i)

        raise ASN1Error, "OBJECT ID #{@name}: first subidentifier should be less than 3" if ids[0] > 2
        raise ASN1Error, "OBJECT ID #{@name}: second subidentifier should be less than 40" if (ids[0] < 2) && (ids[1] > 39)

        ids[0, 2] = ids[0] * 40 + ids[1]
        ids.map! do |v|
          next v if v < 128

          unsigned_to_chained_octets(v)
        end
        ids.flatten.pack('C*')
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        bytes = der.unpack('C*')

        ids = []
        current_id = 0
        bytes.each do |byte|
          current_id = (current_id << 7) | (byte & 0x7f)
          if (byte & 0x80).zero?
            ids << current_id
            current_id = 0
          end
        end

        first_id = [2, ids.first / 40].min
        second_id = ids.first - first_id * 40
        ids[0..0] = [first_id, second_id]

        @value = ids.join('.')
      end
    end
  end
end
