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
        utc_offset_forced = false

        if (date_hour[-1] != 'Z') && (date_hour !~ /[+-]\d+$/)
          # If not UTC, have to add offset with UTC to force
          # DateTime#strptime to generate a local time. But this difference
          # may be errored because of DST.
          date_hour << Time.now.strftime('%z')
          utc_offset_forced = true
        end

        value_from(date_hour)
        fix_dst if utc_offset_forced
      end

      def value_when_fraction_ends_with_z(date_hour, fraction)
        fraction = fraction[0...-1]
        date_hour << 'Z'
        frac_base = value_from(date_hour)
        fix_value(fraction, frac_base)
      end

      def value_on_others_cases(date_hour, fraction)
        match = fraction.match(/(\d+)([+-]\d+)/)
        if match
          # fraction contains fraction and timezone info. Split them
          fraction = match[1]
          date_hour << match[2]
        else
          # fraction only contains fraction.
          # Have to add offset with UTC to force DateTime#strptime to
          # generate a local time. But this difference may be errored
          # because of DST.
          date_hour << Time.now.strftime('%z')
          utc_offset_forced = true
        end

        frac_base = value_from(date_hour)
        fix_dst if utc_offset_forced
        fix_value(fraction, frac_base)
      end

      def value_from(date_hour)
        format, frac_base = strformat(date_hour)
        @value = Strptime.new(format).exec(date_hour)
        frac_base
      end

      # Check DST. There may be a shift of one hour...
      def fix_dst
        #compare_time = Time.new(@value.year, @value.month, @value.mday, @value.hour, @value.minute, @value.sec)
        #@value = compare_time if compare_time.utc_offset != @value.to_time.utc_offset
      end

      def fix_value(fraction, frac_base)
        frac = ".#{fraction}".to_r * frac_base
        @value = (@value + frac) unless fraction.nil?
      end

      def strformat(date_hour) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        case date_hour.size
        when 11
          frac_base = HOUR_TO_SEC
          format = '%Y%m%d%H%z'
        when 13
          frac_base = MINUTE_TO_SEC
          format = '%Y%m%d%H%M%z'
        when 15
          if date_hour[-1] == 'Z'
            frac_base = SECOND_TO_SEC
            format = '%Y%m%d%H%M%S%z'
          else
            frac_base = HOUR_TO_SEC
            format = '%Y%m%d%H%z'
          end
        when 17
          frac_base = MINUTE_TO_SEC
          format = '%Y%m%d%H%M%z'
        when 19
          frac_base = SECOND_TO_SEC
          format = '%Y%m%d%H%M%S%z'
        else
          prefix = @name.nil? ? type : "tag #{@name}"
          raise ASN1Error, "#{prefix}: unrecognized format: #{date_hour}"
        end

        [format, frac_base]
      end
    end
  end
end
