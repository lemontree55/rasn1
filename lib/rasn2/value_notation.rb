# frozen_string_literal: true

module RASN2
  # Support for ASN.1 value notation (text representation of ASN.1 data instances).
  #
  # ASN.1 value notation allows defining values for ASN.1 types in a human-readable
  # text format. For example:
  #   myPerson PersonnelRecord ::= {
  #       name    "John Doe",
  #       title   "Engineer",
  #       age     30,
  #       employed TRUE
  #   }
  #
  # This module provides methods to parse such text into {Model} instances and
  # to generate such text from {Model} instances.
  #
  # @example Parse a value notation string
  #   models = RASN2::SchemaParser.parse_file('schema.asn')
  #   record = RASN2::ValueNotation.parse(
  #     File.read('instance.asn'),
  #     models: models
  #   )
  #   record[:name].value  # => "John Doe"
  #
  # @example Generate value notation from a model
  #   record = PersonnelRecord.new(name: 'John Doe', title: 'Engineer', age: 30, employed: true)
  #   text = RASN2::ValueNotation.emit(record, name: 'myPerson', type_name: 'PersonnelRecord')
  #
  # @author rickmark
  # @since 0.17.0
  module ValueNotation
    # Error raised when parsing or emitting value notation fails
    class Error < RASN2::Error; end

    class << self
      # Parse an ASN.1 value notation string and populate a model instance.
      # @param [String] text the value notation text
      # @param [Hash{String => Class}] models hash mapping type names to Model subclasses
      # @return [Model] populated model instance
      # @raise [Error] if the text cannot be parsed
      def parse(text, models:)
        text = text.strip
        match = text.match(/\A(\w+)\s+(\w+)\s*::=\s*(.*)\z/m)
        raise Error, 'Invalid value notation format' unless match

        value_name = match[1]
        type_name = match[2]
        body = match[3].strip

        model_class = models[type_name]
        raise Error, "Unknown type: #{type_name}" unless model_class

        values = parse_constructed_value(body)
        instance = model_class.new(values)
        instance.define_singleton_method(:value_name) { value_name }
        instance.define_singleton_method(:type_name) { type_name }
        instance
      end

      # Parse an ASN.1 value notation file.
      # @param [String] filename path to the value notation file
      # @param [Hash{String => Class}] models hash mapping type names to Model subclasses
      # @return [Model] populated model instance
      # @raise [Error] if the file cannot be parsed
      def parse_file(filename, models:)
        parse(File.read(filename), models: models)
      end

      # Emit ASN.1 value notation text from a model instance.
      # @param [Model] model the model instance to emit
      # @param [String] name the value name (e.g. 'myPerson')
      # @param [String] type_name the type name (e.g. 'PersonnelRecord')
      # @param [Integer] indent indentation level (number of spaces per level)
      # @return [String] value notation text
      def emit(model, name: nil, type_name: nil)
        name ||= model.respond_to?(:value_name) ? model.value_name : 'value'
        type_name ||= model.respond_to?(:type_name) ? model.type_name : model.class.type
        body = emit_constructed(model, indent_level: 1)
        "#{name} #{type_name} ::= {\n#{body}\n}\n"
      end

      private

      # Parse a constructed value body: { field1 value1, field2 value2, ... }
      # @param [String] text
      # @return [Hash{Symbol => Object}]
      def parse_constructed_value(text)
        text = text.strip
        raise Error, "Expected '{' at start of constructed value" unless text.start_with?('{')
        raise Error, "Expected '}' at end of constructed value" unless text.end_with?('}')

        inner = text[1..-2].strip
        result = {}
        remaining = inner

        until remaining.nil? || remaining.strip.empty?
          remaining = remaining.strip
          field_name, value, remaining = parse_field(remaining)
          result[field_name.to_sym] = value
          # consume optional comma
          remaining = remaining&.strip
          remaining = remaining.sub(/\A,\s*/, '') if remaining&.start_with?(',')
        end

        result
      end

      # Parse a single field: name value
      # @param [String] text
      # @return [Array(String, Object, String)] field name, parsed value, remaining text
      def parse_field(text)
        # Match field name
        match = text.match(/\A(\w+)\s+/)
        raise Error, "Expected field name in: #{text[0..40]}" unless match

        field_name = match[1]
        rest = match.post_match

        value, rest = parse_value(rest)
        [field_name, value, rest]
      end

      # Parse a single value (string, integer, boolean, null, or nested constructed)
      # @param [String] text
      # @return [Array(Object, String)] parsed value and remaining text
      def parse_value(text)
        text = text.strip
        case text
        when /\A"/ then parse_string_value(text)
        when /\ATRUE\b/i then [true, text.sub(/\ATRUE/i, '')]
        when /\AFALSE\b/i then [false, text.sub(/\AFALSE/i, '')]
        when /\ANULL\b/i then [nil, text.sub(/\ANULL/i, '')]
        when /\A\{/ then parse_nested_constructed(text)
        when /\A-?\d/ then parse_integer_value(text)
        else
          raise Error, "Unexpected value at: #{text[0..40]}"
        end
      end

      # Parse a quoted string value
      # @param [String] text
      # @return [Array(String, String)]
      def parse_string_value(text)
        # Handle escaped quotes within the string
        pos = 1
        result = +''
        while pos < text.length
          ch = text[pos]
          if ch == '"'
            # Check for escaped quote (doubled)
            return [result, text[(pos + 1)..]] unless pos + 1 < text.length && text[pos + 1] == '"'

            result << '"'
            pos += 2

          else
            result << ch
            pos += 1
          end
        end
        raise Error, 'Unterminated string value'
      end

      # Parse an integer value
      # @param [String] text
      # @return [Array(Integer, String)]
      def parse_integer_value(text)
        match = text.match(/\A(-?\d+)/)
        raise Error, "Expected integer at: #{text[0..20]}" unless match

        [match[1].to_i, match.post_match]
      end

      # Parse a nested constructed value { ... }
      # @param [String] text
      # @return [Array(Hash, String)]
      def parse_nested_constructed(text)
        # Find matching closing brace
        depth = 0
        pos = 0
        text.each_char.with_index do |ch, idx|
          depth += 1 if ch == '{'
          depth -= 1 if ch == '}'
          if depth.zero?
            pos = idx
            break
          end
        end
        raise Error, 'Unmatched braces in constructed value' if depth != 0

        inner_text = text[0..pos]
        rest = text[(pos + 1)..]
        values = parse_constructed_value(inner_text)
        [values, rest]
      end

      # Emit the fields of a constructed model value
      # @param [Model] model
      # @param [Integer] indent_level
      # @return [String]
      def emit_constructed(model, indent_level: 1)
        indent = '    ' * indent_level
        fields = collect_fields(model)

        lines = fields.map do |field_name, value|
          formatted = format_value(value, indent_level: indent_level)
          "#{indent}#{field_name} #{formatted}"
        end

        lines.join(",\n")
      end

      # Collect the named fields from a model's root sequence
      # @param [Model] model
      # @return [Array<Array(Symbol, Object)>]
      def collect_fields(model)
        root = model.root
        return [] unless root.is_a?(Types::Sequence) || root.is_a?(Types::Set)
        return [] unless root.value.is_a?(Array)

        fields = []
        root.value.each do |element|
          case element
          when Model
            fields << [element.name, element]
          when Types::Base
            next if element.optional? && !element.value?

            fields << [element.name, element.value]
          end
        end
        fields
      end

      # Format a value for value notation output
      # @param [Object] value
      # @param [Integer] indent_level
      # @return [String]
      def format_value(value, indent_level: 0)
        case value
        when Model
          body = emit_constructed(value, indent_level: indent_level + 1)
          "{\n#{body}\n#{'    ' * indent_level}}"
        when true then 'TRUE'
        when false then 'FALSE'
        when ::Integer then value.to_s
        when String then "\"#{value.gsub('"', '""')}\""
        when nil then 'NULL'
        else
          value.to_s
        end
      end
    end
  end
end
