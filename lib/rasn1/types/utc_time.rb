# frozen_string_literal: true

require 'date'

module RASN1
  module Types
    # ASN.1 UTCTime
    #
    # +{#value} of a +UtcTime+ should be a ruby Time.
    #
    # ===Notes
    # When encoding, resulting string is always a UTC time, appended with +Z+.
    # Seconds are always generated.
    #
    # On parsing, UTC times (ending with +Z+) and local times (ending with
    # +sHHMM+, where +s+ is +++ or +-+, and +HHMM+ is the time differential
    # betwen UTC and local time) are both supported. Seconds may be present or
    # not.
    # @author Sylvain Daubert
    class UtcTime < Primitive
      # UtcTime id value
      ID = 23

      # Get ASN.1 type
      # @return [String]
      def self.type
        'UTCTime'
      end

      private

      def value_to_der
        @value.getutc.strftime('%y%m%d%H%M%SZ')
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        format = case der.size
                 when 11, 15
                   '%Y%m%d%H%M%z'
                 when 13, 17
                   '%Y%m%d%H%M%S%z'
                 else
                   prefix = @name.nil? ? type : "tag #{@name}"
                   raise ASN1Error, "#{prefix}: unrecognized format: #{der}"
                 end
        century = (Time.now.year / 100).to_s
        @value = Strptime.new(format).exec(century + der)
      end

      def trace_data
        return super if explicit?

        +'    ' << raw_data
      end
    end
  end
end
