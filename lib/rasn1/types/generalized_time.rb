# frozen_string_literal: true

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

      # Get ASN.1 type
      # @return [String]
      def self.type
        'GeneralizedTime'
      end

      private

      def value_to_der
        if @value.nsec.positive?
          der = @value.getutc.strftime('%Y%m%d%H%M%S.%9NZ')
          der.sub(/0+Z/, 'Z')
        else
          @value.getutc.strftime('%Y%m%d%H%M%SZ')
        end
      end

      def der_to_value(der, ber: false)
        date_hour, fraction = der.split('.')
        utc_offset_forced = false
        if fraction.nil?
          if (date_hour[-1] != 'Z') && (date_hour !~ /[+-]\d+$/)
            # If not UTC, have to add offset with UTC to force
            # DateTime#strptime to generate a local time. But this difference
            # may be errored because of DST.
            date_hour << Time.now.strftime('%z')
            utc_offset_forced = true
          end
        elsif fraction[-1] == 'Z'
          fraction = fraction[0...-1]
          date_hour << 'Z'
        else
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
        end
        format = case date_hour.size
                 when 11
                   frac_base = 60 * 60
                   '%Y%m%d%HZ'
                 when 13
                   frac_base = 60
                   '%Y%m%d%H%MZ'
                 when 15
                   if date_hour[-1] == 'Z'
                     frac_base = 1
                     '%Y%m%d%H%M%SZ'
                   else
                     frac_base = 60 * 60
                     '%Y%m%d%H%z'
                   end
                 when 17
                   frac_base = 60
                   '%Y%m%d%H%M%z'
                 when 19
                   frac_base = 1
                   '%Y%m%d%H%M%S%z'
                 else
                   prefix = @name.nil? ? type : "tag #{@name}"
                   raise ASN1Error, "#{prefix}: unrecognized format: #{der}"
                 end
        @value = DateTime.strptime(date_hour, format).to_time
        # local time format.
        # Check DST. There may be a shift of one hour...
        if utc_offset_forced
          compare_time = Time.new(*@value.to_a[0..5].reverse)
          @value = compare_time if compare_time.utc_offset != @value.utc_offset
        end
        @value += ".#{fraction}".to_r * frac_base unless fraction.nil?
      end
    end
  end
end
