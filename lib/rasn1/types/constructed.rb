# frozen_string_literal: true

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
          str = common_inspect(level)
          str << "\n"
          level = level.abs + 1
          @value.each do |item|
            case item
            when Base, Model
              str << "#{item.inspect(level)}\n"
            else
              str << '  ' * level
              str << "#{item.inspect}\n"
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
