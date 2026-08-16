# frozen_string_literal: true

module RASN2
  # Parser for ASN.1 text schema definitions.
  #
  # Parses ASN.1 module definitions and generates {Model} subclasses from them.
  #
  # @example Parse a schema file
  #   models = RASN2::SchemaParser.parse_file('path/to/schema.asn')
  #   # => { 'PersonnelRecord' => PersonnelRecord (class < RASN2::Model) }
  #
  # @example Parse a schema string
  #   schema = <<~ASN1
  #     MyModule DEFINITIONS ::=
  #     BEGIN
  #       MyRecord ::= SEQUENCE {
  #         name  PrintableString,
  #         age   INTEGER
  #       }
  #     END
  #   ASN1
  #   models = RASN2::SchemaParser.parse(schema)
  #
  # @author rickmark
  # @since 0.16.0
  module SchemaParser
    # ASN.1 type name to RASN2 type DSL method mapping
    TYPE_MAP = {
      'BOOLEAN' => :boolean,
      'INTEGER' => :integer,
      'BIT STRING' => :bit_string,
      'OCTET STRING' => :octet_string,
      'NULL' => :null,
      'OBJECT IDENTIFIER' => :objectid,
      'ENUMERATED' => :enumerated,
      'UTF8String' => :utf8_string,
      'PrintableString' => :printable_string,
      'IA5String' => :ia5_string,
      'VisibleString' => :visible_string,
      'NumericString' => :numeric_string,
      'BMPString' => :bmp_string,
      'UniversalString' => :universal_string,
      'UTCTime' => :utc_time,
      'GeneralizedTime' => :generalized_time
    }.freeze

    # Constructed type names
    CONSTRUCTED_TYPES = %w[SEQUENCE SET TAG].freeze

    # Error raised when parsing an ASN.1 schema fails
    class ParseError < RASN2::Error; end

    class << self
      # Parse an ASN.1 schema from a file and generate Model classes.
      # @param [String] filename path to the ASN.1 schema file
      # @param [Module] namespace module in which to define the generated classes (default: Object)
      # @return [Hash{String => Class}] hash mapping type names to generated Model subclasses
      # @raise [ParseError] if the schema cannot be parsed
      def parse_file(filename, namespace: Object)
        parse(File.read(filename), namespace: namespace)
      end

      # Parse an ASN.1 schema string and generate Model classes.
      # @param [String] schema the ASN.1 schema text
      # @param [Module] namespace module in which to define the generated classes (default: Object)
      # @return [Hash{String => Class}] hash mapping type names to generated Model subclasses
      # @raise [ParseError] if the schema cannot be parsed
      def parse(schema, namespace: Object)
        mod = parse_module(schema)
        build_models(mod, namespace: namespace)
      end

      private

      # Parse the module header and body
      # @return [Hash] parsed module structure with :name, :tag_default, :definitions
      def parse_module(schema)
        lines = schema.strip
        # Match module header: ModuleName DEFINITIONS [tag_default] ::=
        header_match = lines.match(/\A(\w+)\s+DEFINITIONS\s*(.*?)\s*::=\s*\n\s*BEGIN\s*\n(.*)\nEND\s*\z/m)
        raise ParseError, 'Invalid ASN.1 module format' unless header_match

        mod_name = header_match[1]
        tag_options = header_match[2].strip
        body = header_match[3]

        tag_default = parse_tag_default(tag_options)

        definitions = parse_definitions(body)

        { name: mod_name, tag_default: tag_default, definitions: definitions }
      end

      # Parse tag default from module header
      # @return [Symbol,nil] :implicit, :explicit, or nil
      def parse_tag_default(tag_str)
        case tag_str
        when /IMPLICIT\s+TAGS/i then :implicit
        when /EXPLICIT\s+TAGS/i then :explicit
        when /AUTOMATIC\s+TAGS/i then :automatic
        end
      end

      # Parse all type definitions from the module body
      # @return [Array<Hash>] list of type definitions
      def parse_definitions(body)
        definitions = []
        # Split on type assignments: TypeName ::= ...
        # We need to handle multi-line definitions
        remaining = body.strip

        while remaining && !remaining.empty?
          # Match: TypeName ::= TypeDefinition
          match = remaining.match(/\A\s*(\w+)\s*::=\s*/m)
          break unless match

          type_name = match[1]
          rest = match.post_match

          type_def, rest = parse_type_definition(rest)
          definitions << { name: type_name, type: type_def }
          remaining = rest&.strip
        end

        definitions
      end

      # Parse a single type definition
      # @return [Array(Hash, String)] the parsed type and remaining text
      def parse_type_definition(text)
        text = text.strip

        # Check for constructed types: SEQUENCE { ... }, SET { ... }
        case text
        when /\A(SEQUENCE|SET)\s+OF\b/
          parse_of_type(text)
        when /\A(SEQUENCE|SET)\s*\{/
          parse_constructed_type(text)
        when /\A(CHOICE)\s*\{/
          parse_choice_type(text)
        else
          parse_simple_type_definition(text)
        end
      end

      # Parse SEQUENCE { ... } or SET { ... }
      # @return [Array(Hash, String)]
      def parse_constructed_type(text)
        match = text.match(/\A(SEQUENCE|SET)\s*\{/m)
        raise ParseError, "Expected SEQUENCE or SET, got: #{text[0..20]}" unless match

        kind = match[1].downcase.to_sym
        rest = match.post_match
        members, rest = parse_members(rest)

        [{ kind: kind, members: members }, rest]
      end

      # Parse CHOICE { ... }
      # @return [Array(Hash, String)]
      def parse_choice_type(text)
        match = text.match(/\A(CHOICE)\s*\{/m)
        raise ParseError, "Expected CHOICE, got: #{text[0..20]}" unless match

        rest = match.post_match
        members, rest = parse_members(rest)

        [{ kind: :choice, members: members }, rest]
      end

      # Parse SEQUENCE OF or SET OF
      # @return [Array(Hash, String)]
      def parse_of_type(text)
        match = text.match(/\A(SEQUENCE|SET)\s+OF\s+/m)
        raise ParseError, 'Expected SEQUENCE OF or SET OF' unless match

        kind = :"#{match[1].downcase}_of"
        rest = match.post_match
        element_type, rest = parse_type_reference(rest)

        [{ kind: kind, element_type: element_type }, rest]
      end

      # Parse a simple (non-constructed) top-level type definition (type alias)
      # @return [Array(Hash, String)]
      def parse_simple_type_definition(text)
        type_name, = parse_type_reference(text)
        raise ParseError, "Unsupported simple type alias at top level: #{type_name}" unless TYPE_MAP.key?(type_name) || type_name.is_a?(Hash)

        # Simple type aliases are not directly supported as Model subclasses
        # They would need to be handled as constrained types
        raise ParseError, 'Simple type aliases are not yet supported as top-level definitions'
      end

      # Parse the members inside { ... }
      # @return [Array(Array<Hash>, String)]
      def parse_members(text)
        members = []
        rest = text.strip

        loop do
          # Check for closing brace
          if rest.match?(/\A\s*\}/)
            rest = rest.sub(/\A\s*\}/, '')
            break
          end

          # Remove leading comma
          rest = rest.sub(/\A\s*,\s*/, '') unless members.empty?

          member, rest = parse_member(rest.strip)
          members << member if member
        end

        [members, rest]
      end

      # Parse a single member: name Type [constraints] [DEFAULT value | OPTIONAL]
      # @return [Array(Hash, String)]
      def parse_member(text)
        text = text.strip
        return [nil, text] if text.empty? || text.start_with?('}')

        # Match: fieldName Type
        match = text.match(/\A(\w+)\s+/)
        raise ParseError, "Expected field name, got: #{text[0..30]}" unless match

        field_name = match[1]
        rest = match.post_match

        type_info, rest = parse_type_with_constraints(rest)

        member = { name: field_name, type: type_info[:type], options: type_info[:options] }
        [member, rest]
      end

      # Parse a type followed by optional constraints, DEFAULT, or OPTIONAL
      # @return [Array(Hash, String)]
      def parse_type_with_constraints(text)
        text = text.strip
        type_name, rest = parse_type_reference(text)

        options = {}

        # Parse constraints like (0..120)
        rest = rest.strip
        if rest.start_with?('(')
          _constraint, rest = parse_constraint(rest)
          # Constraints are noted but not enforced at model level currently
        end

        # Parse DEFAULT or OPTIONAL
        rest = rest.strip
        if rest.match?(/\ADEFAULT\b/)
          rest = rest.sub(/\ADEFAULT\s+/, '')
          default_value, rest = parse_default_value(rest)
          options[:default] = default_value
        elsif rest.match?(/\AOPTIONAL\b/)
          rest = rest.delete_prefix('OPTIONAL')
          options[:optional] = true
        end

        [{ type: type_name, options: options }, rest]
      end

      # Parse a type reference (simple type name or constructed inline type)
      # @return [Array(String, String)]
      def parse_type_reference(text)
        text = text.strip

        # Check for inline constructed types
        case text
        when /\A(SEQUENCE|SET)\s*\{/
          type_def, rest = parse_constructed_type(text)
          return [type_def, rest]
        when /\A(SEQUENCE|SET)\s+OF\b/
          type_def, rest = parse_of_type(text)
          return [type_def, rest]
        when /\A(CHOICE)\s*\{/
          type_def, rest = parse_choice_type(text)
          return [type_def, rest]
        end

        # Multi-word types
        ['BIT STRING', 'OCTET STRING', 'OBJECT IDENTIFIER'].each do |multi|
          return [multi, text[multi.length..]] if text.start_with?(multi)
        end

        # Simple type name
        match = text.match(/\A([A-Za-z][\w-]*)/)
        raise ParseError, "Expected type name, got: #{text[0..20]}" unless match

        [match[1], match.post_match]
      end

      # Parse a constraint expression like (0..120)
      # @return [Array(String, String)]
      def parse_constraint(text)
        depth = 0
        idx = 0
        text.each_char do |c|
          depth += 1 if c == '('
          depth -= 1 if c == ')'
          idx += 1
          break if depth.zero?
        end
        [text[0...idx], text[idx..]]
      end

      # Parse a default value
      # @return [Array(Object, String)]
      def parse_default_value(text)
        text = text.strip

        case text
        when /\ATRUE\b/
          [true, text.delete_prefix('TRUE')]
        when /\AFALSE\b/
          [false, text.delete_prefix('FALSE')]
        when /\ANULL\b/
          [nil, text.delete_prefix('NULL')]
        when /\A(-?\d+)\b/
          [Regexp.last_match(1).to_i, Regexp.last_match.post_match]
        when /\A"([^"]*)"/
          [Regexp.last_match(1), Regexp.last_match.post_match]
        else
          # Try to capture an identifier (enum value, etc.)
          match = text.match(/\A(\w+)/)
          raise ParseError, "Cannot parse default value: #{text[0..20]}" unless match

          [match[1], match.post_match]
        end
      end

      # Build Model classes from parsed definitions
      # @return [Hash{String => Class}]
      def build_models(mod, namespace:)
        models = {}

        mod[:definitions].each do |defn|
          klass = build_model_class(defn[:name], defn[:type], mod, models, namespace)
          models[defn[:name]] = klass
        end

        models
      end

      # Build a single Model subclass
      # @return [Class]
      def build_model_class(type_name, type_def, mod, existing_models, namespace)
        klass = Class.new(RASN2::Model)

        root_name = type_name.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').downcase.to_sym

        case type_def[:kind]
        when :sequence, :set
          build_constructed(klass, root_name, type_def, mod, existing_models)
        when :choice
          build_choice(klass, root_name, type_def, mod, existing_models)
        when :sequence_of, :set_of
          build_of(klass, root_name, type_def, mod, existing_models)
        else
          raise ParseError, "Unsupported top-level type: #{type_def.inspect}"
        end

        # Define the class in the namespace
        namespace.const_set(type_name.to_sym, klass) unless namespace.const_defined?(type_name.to_sym, false)

        klass
      end

      # Build a SEQUENCE or SET model
      def build_constructed(klass, root_name, type_def, mod, existing_models)
        members = type_def[:members]
        mod[:tag_default]

        klass.class_eval do
          content_elems = members.map do |member|
            field_name = member[:name].to_sym
            type_ref = member[:type]
            opts = (member[:options] || {}).dup

            if type_ref.is_a?(Hash)
              # Inline constructed type - not supported as a simple field
              raise SchemaParser::ParseError, "Inline constructed types not yet supported for field #{field_name}"
            end

            method_sym = SchemaParser.type_to_method(type_ref)
            if method_sym
              send(method_sym, field_name, **opts)
            elsif existing_models[type_ref]
              model(field_name, existing_models[type_ref])
            else
              raise SchemaParser::ParseError, "Unknown type: #{type_ref}"
            end
          end

          send(type_def[:kind], root_name, content: content_elems)
        end
      end

      # Build a CHOICE model
      def build_choice(klass, root_name, type_def, _mod, existing_models)
        members = type_def[:members]

        klass.class_eval do
          content_elems = members.map do |member|
            field_name = member[:name].to_sym
            type_ref = member[:type]
            opts = (member[:options] || {}).dup

            method_sym = SchemaParser.type_to_method(type_ref)
            if method_sym
              send(method_sym, field_name, **opts)
            elsif existing_models[type_ref]
              model(field_name, existing_models[type_ref])
            else
              raise SchemaParser::ParseError, "Unknown type: #{type_ref}"
            end
          end

          choice(root_name, content: content_elems)
        end
      end

      # Build a SEQUENCE OF or SET OF model
      def build_of(klass, root_name, type_def, _mod, existing_models)
        element_type = type_def[:element_type]

        klass.class_eval do
          method_sym = SchemaParser.type_to_method(element_type)
          if method_sym
            # For OF types with primitive elements, use the type class
            type_class = SchemaParser.type_to_class(element_type)
            send(type_def[:kind], root_name, type_class)
          elsif existing_models[element_type]
            send(type_def[:kind], root_name, existing_models[element_type])
          else
            raise SchemaParser::ParseError, "Unknown type for #{type_def[:kind]}: #{element_type}"
          end
        end
      end

      # Build Model classes from parsed definitions
      # (end of private section)
    end

    # Convert an ASN.1 type name to the corresponding RASN2 Model DSL method symbol
    # @param [String] type_name
    # @return [Symbol, nil]
    def self.type_to_method(type_name)
      TYPE_MAP[type_name]
    end

    # Convert an ASN.1 type name to the corresponding RASN2::Types class
    # @param [String] type_name
    # @return [Class, nil]
    def self.type_to_class(type_name)
      method_sym = TYPE_MAP[type_name]
      return nil unless method_sym

      class_name = type_name.gsub(/\s+/, '')
      begin
        Types.const_get(class_name)
      rescue NameError
        nil
      end
    end
  end
end
