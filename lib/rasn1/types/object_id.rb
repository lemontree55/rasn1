module RASN1
  module Types

    # ASN.1 Object ID
    # @author Sylvain Daubert
    class ObjectId < Primitive
      TAG = 6

      private

      def value_to_der
        ids = @value.split('.').map! { |str| str.to_i }

        if ids[0] > 2
          raise ASN1Error, 'OBJECT ID #@name: first subidentifier should be less than 3'
        end
        if ids[0] < 2 and ids[1] > 39
          raise ASN1Error, 'OBJECT ID #@name: second subidentifier should be less than 40'
        end

        ids[0, 2] = ids[0] * 40 + ids[1]
        ids.map! do |v|
          next v if v < 128

          ary = []
          while v > 0
            ary.unshift (v & 0x7f) | 0x80
            v >>= 7
          end
          ary[-1] &= 0x7f
          ary
        end
        ids.flatten.pack('C*')
      end

      def der_to_value(der, ber: false)
        bytes = der.unpack('C*')
        ids = if bytes[0] < 80
                remove = 1
                [ bytes[0] / 40, bytes[0] % 40]
              elsif bytes[0] < 128
                remove = 1
                [2, bytes[0] - 80]
              else
                remove = 1
                second_id = bytes[0] & 0x7f
                bytes[1..-1].each do |byte|
                  remove += 1
                  second_id <<= 7
                  if byte < 128
                    second_id |= byte
                    break
                  else
                    second_id |= byte & 0x7f
                  end
                end
                [2, second_id - 80]
              end

        id = 0
        bytes.shift(remove)
        bytes.each do |byte|
          if byte < 128
            if id == 0
              ids << byte
            else
              ids << ((id << 7) | byte)
              id = 0
            end
          else
            id = (id << 7) | (byte & 0x7f)
          end
        end

        @value = ids.join('.')
      end
    end
  end
end
