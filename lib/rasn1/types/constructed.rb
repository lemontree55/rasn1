module RASN1
  module Types
    # @abstract This class SHOULD be used as base class for all ASN.1 primitive
    #  types.
    # Base class for all ASN.1 constructed types
    # @author Sylvain Daubert
    class Constructed < Base
      # Constructed value
      ASN1_PC = 0x20

      def inspect(level=0)
        case @value
        when Array
          str = ''
          str << '  ' * level if level.positive?
          str << "#{@name} " unless @name.nil?
          level = level.abs
          str << "#{type}:\n"
          level += 1
          @value.each do |item|
            case item
            when Base, Model
              next if item.optional? && item.value.nil?

              str << "#{item.inspect(level)}\n"
            else
              str << '  ' * level + item.inspect + "\n"
            end
          end
          str
        else
          super
        end
      end
    end
  end
end
