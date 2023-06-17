# frozen_string_literal: true

require 'strptime'

module RASN1
  module Types
    # ASN.1 GeneralizedTime
    #
    # +{#value} of a {GeneralizedTime} should be a ruby Time.
    #
    # ===Notes
    # When encoding, resulting string is always a UTC time, appended with +Z+.
    # Minutes and seconds are always generated. Fractions of second are generated
    # if value Time object have them.
    #
    # On parsing, are supported:
    # * UTC times (ending with +Z+),
    # * local times (no suffix),
    # * local times with difference between UTC and this local time (ending with
    #   +sHHMM+, where +s+ is +++ or +-+, and +HHMM+ is the time differential
    #   betwen UTC and local time).
    # These times may include minutes and seconds. Fractions of hour, minute and
    # second are supported.
    # @author Sylvain Daubert
    class GeneralizedTime < Primitive
      # GeneralizedTime id value
      ID = 24

      # @private
      HOUR_TO_SEC = 3600
      # @private
      MINUTE_TO_SEC = 60
      # @private
      SECOND_TO_SEC = 1

      # Get ASN.1 type
      # @return [String]
      def self.type
        'GeneralizedTime'
      end

      # @return [Time]
      def void_value
        Time.now
      end

      private

      def value_to_der
        utc_value = @value.getutc
        if utc_value.nsec.positive?
          der = utc_value.strftime('%Y%m%d%H%M%S.%9NZ')
          der.sub(/0+Z/, 'Z')
        else
          utc_value.strftime('%Y%m%d%H%M%SZ')
        end
      end

      def der_to_value(der, ber: false) # rubocop:disable Lint/UnusedMethodArgument
        date_hour, fraction = der.split('.')
        date_hour = date_hour.to_s
        fraction = fraction.to_s

        if fraction.empty?
          value_when_fraction_empty(date_hour)
        elsif fraction[-1] == 'Z'
          value_when_fraction_ends_with_z(date_hour, fraction)
        else
          value_on_others_cases(date_hour, fraction)
        end
      end

      def value_when_fraction_empty(date_hour)
        tz = if date_hour[-1] == 'Z'
               date_hour.slice!(-1, 1)
               '+00:00' # Ruby 3.0: to remove after end-of support of ruby 3.0
             elsif date_hour.match?(/[+-]\d+$/)
               # Ruby 3.0
               # date_hour.slice!(-5, 5)
               zone = date_hour.slice!(-5, 5)
               zone[0, 3] << ':' << zone[3, 2]
             end
        year = date_hour.slice!(0, 4).to_i
        others = date_hour.scan(/../).map(&:to_i)
        # Ruby 3.0
        # From 3.1: "Z" and "-0100" are supported
        # Below 3.1: should be "-01:00" or "+00:00"
        unless tz.nil?
          others += [0] * (5 - others.size)
          others << tz
        end
        @value = Time.new(year, *others)
        # From 3.1: replace all this code by: Time.new(year, *others, in: tz)
      end

      def value_when_fraction_ends_with_z(date_hour, fraction)
        fraction = fraction[0...-1]
        date_hour << 'Z'
        frac_base = compute_frac_base(date_hour)
        value_when_fraction_empty(date_hour)
        fix_value(fraction, frac_base)
      end

      def value_on_others_cases(date_hour, fraction)
        match = fraction.match(/(\d+)([+-]\d+)/)
        if match
          # fraction contains fraction and timezone info. Split them
          fraction = match[1]
          date_hour << match[2]
        end

        frac_base = compute_frac_base(date_hour)
        value_when_fraction_empty(date_hour)
        fix_value(fraction, frac_base)
      end

      def fix_value(fraction, frac_base)
        frac = ".#{fraction}".to_r * frac_base
        @value = (@value + frac) unless fraction.nil?
      end

      def compute_frac_base(date_hour)
        case date_hour.size
        when 10, 11
          HOUR_TO_SEC
        when 12, 13, 17
          MINUTE_TO_SEC
        when 15
          if date_hour[-1] == 'Z'
            SECOND_TO_SEC
          else
            HOUR_TO_SEC
          end
        when 14, 19
          SECOND_TO_SEC
        else
          prefix = @name.nil? ? type : "tag #{@name}"
          raise ASN1Error, "#{prefix}: unrecognized format: #{date_hour}"
        end
      end

      def trace_data
        return super if explicit?

        +'    ' << raw_data
      end
    end
  end
end
