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

      # @return [Boolean]
      # @since 0.12.0
      # @see Base#can_build?
      def can_build? # rubocop:disable Metrics/CyclomaticComplexity
        return super unless @value.is_a?(Array) && optional?
        return false unless super

        @value.any? do |el|
          el.can_build? && (
            el.primitive? ||
              (el.value.respond_to?(:empty?) ? !el.value.empty? : !el.value.nil?))
        end
      end

      # @param [::Integer] level (default: 0)
      # @return [String]
      def inspect(level=0)
        case @value
        when Array
          str = common_inspect(level)
          str << "\n"
          level = level.abs + 1
          @value.each do |item|
            case item
            when Base, Model, Wrapper
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
