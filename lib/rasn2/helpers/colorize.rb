# frozen_string_literal: true

module RASN2
  module Helpers
    module Colorize
      def colorizer
        @colorizer&.first || Rainbow.new
      end

      def colorizer=(colorizer)
        @colorizer ||= []
        @colorizer << colorizer
      end

      def begin_colorizer(color)
        @colorizer ||= []
        @colorizer << Rainbow.new
        @colorizer.last.enabled = color
      end

      def colorize(msg)
        colorizer.wrap(msg)
      end

      def end_colorizer
        @colorizer&.pop
      end

      def parens_hex(input, padding=2)
        value = if input.is_a?(Integer)
                  if input >= 0
                    value = "%0#{padding}X" % input
                    value = value.rjust((value.length + 1) / 2 * 2, '0')
                    "0x#{value}"
                  else
                    '0xFF'
                  end
                else
                  input
                end
        "#{colorize('(').webgray}#{colorize(value).blue}#{colorize(')').webgray}"
      end

      def int_with_hex(input, raw_value=nil)
        if raw_value.nil?
          "#{colorize(input).blue} #{parens_hex(input)}"
        else
          "#{colorize(input).blue} #{parens_hex(raw_value)}"
        end
      end

      def brace_surround(input)
        "#{colorize('[').webgray} #{input} #{colorize(']').webgray}"
      end

      def colorize_class(name, tag_id=nil, *attributes)
        parts = [colorize(name).bold.yellow]
        parts += attributes.map { |attr| colorize_attribute(attr) } if attributes.any?
        parts << parens_hex(tag_id) if tag_id
        parts.join(' ')
      end

      def colorize_id(id, tag_class=nil)
        id = id.strip if id.is_a? String
        tag_class = tag_class.strip if tag_class.is_a? String
        tag_class = '' if tag_class == 'UNIVERSAL'

        return '' if id.to_s == '' && tag_class.to_s == ''

        if tag_class && tag_class != ''
          brace_surround("#{colorize_class(tag_class)} #{colorize(id).bold.green}")
        else
          brace_surround(colorize(id).bold.green)
        end
      end

      def length_specifier(data_length, encoded_length=nil)
        encoded_length = data_length if encoded_length.nil?
        "#{colorize('len:').gray} #{colorize(data_length).blue} #{parens_hex(encoded_length)}"
      end

      def colorize_name(name)
        colorize(name).bold.white
      end

      def colorize_attribute(attribute)
        colorize(attribute).bold.magenta
      end

      def colorize_default(value)
        " #{colorize_attribute('DEFAULT VALUE')} #{colorize(value).green.bold}"
      end

      def colorize_nil(name='NONE')
        colorize(name).red.bold
      end

      def colorize_enum(name, raw_value)
        raw_value = "0x#{raw_value.unpack1('H*').upcase}" if raw_value.is_a?(String)
        "#{colorize_class(name)} #{parens_hex(raw_value)}"
      end

      def colorize_value(value)
        colorize(value).blue
      end

      def colorize_bool(value, raw_value)
        hex_raw_value = raw_value.is_a?(String) ? "0x#{raw_value.unpack1('H*').upcase}" : raw_value
        value = if value
                  colorize('TRUE').bold.green
                else
                  colorize('FALSE').bold.red
                end

        "#{value} #{parens_hex(hex_raw_value)}"
      end
    end
  end
end
