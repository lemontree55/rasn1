# frozen_string_literal: true

module RASN2
  module Types
    # ASN.1 Tag constructed type.
    #
    # A Tag type is a constructed element with schematized content
    # (child elements, like a {Sequence}) that can be bound to flexible tag
    # criteria instead of a fixed universal tag:
    # * a single tag number,
    # * a list of possible tag numbers,
    # * any private-class tag.
    #
    # == Binding to a single tag
    #   # Context-class tag 5 (default class is :context)
    #   generic = Tag.new(tag: 5, value: [Integer.new, OctetString.new])
    #   # Application-class tag 10
    #   generic = Tag.new(tag: 10, class: :application, value: [Integer.new])
    #
    # == Binding to a list of tags
    #   generic = Tag.new(tag: [5, 6, 7], value: [Integer.new, OctetString.new])
    #
    # == Binding to any private tag
    #   generic = Tag.new(tag: :private, value: [Integer.new, OctetString.new])
    #   # or equivalently
    #   generic = Tag.new(any_private: true, value: [Integer.new])
    class Tag < Base
      # Placeholder ID — not used directly; tag is always dynamic.
      ID = 0

      # @return [Integer, nil] the tag number that was matched during parsing
      attr_reader :matched_tag

      # @param [Hash] options
      # @option options [Integer, Array<Integer>, :private] :tag tag number(s) to
      #   bind to, or +:private+ to accept any private-class tag
      # @option options [Boolean] :any_private if +true+, accept any private-class tag
      # @see Base#initialize
      def initialize(options={})
        extract_tag_binding(options)
        super
        @no_value = false
        @value ||= []
      end

      # Deep copy
      def initialize_copy(*)
        super
        @value = case @value
                 when Array then @value.map(&:dup)
                 else @value.dup
                 end
        @accepted_tags = @accepted_tags.dup
      end

      # @return [Array]
      def void_value
        []
      end

      # Get element by index or name
      # @param [Integer, String, Symbol] idx_or_name
      # @return [Object, nil]
      def [](idx_or_name)
        return unless @value.is_a?(Array)

        case idx_or_name
        when ::Integer
          @value[idx_or_name.to_i]
        when String, Symbol
          @value.find { |elt| elt.name == idx_or_name }
        end
      end

      def der_to_value(der, ber: false)
        @value = if constructed?
                   [RASN2.parse(der, ber: ber)]
                 else
                   der
                 end
      end

      private

      def extract_tag_binding(options)
        tag = options.delete(:tag)
        @any_private = !options.delete(:any_private).nil?

        @accepted_tags = case tag
                         when Array then tag
                         when ::Integer then [tag]
                         when :private
                           @any_private = true
                           []
                         else
                           []
                         end

        if @any_private
          options[:class] ||= :private
          options[:implicit] = @accepted_tags.first if @accepted_tags.any?
        elsif @accepted_tags.any?
          options[:class] ||= :context
          options[:implicit] = @accepted_tags.first
        end
      end

      def check_id(der)
        asn1_class, pc, tag_id, size = Types.decode_identifier_octets(der)
        @asn1_class = asn1_class
        @constructed = pc
        @tag = tag_id
        @tag_size = size

        return check_any_private_id(der) if @any_private && @accepted_tags.empty?
        return check_multi_tag_id(der) if @accepted_tags.length > 1

        super
      end

      def check_any_private_id(der)
        return no_match(der) if der.nil? || der.empty?

        if asn1_class == :private && @any_private
          true
        else
          @accepted_tags.include?(tag_id)
        end
      end

      def check_multi_tag_id(der)
        original_id = @id_value
        @accepted_tags.each do |tag|
          @id_value = tag
          expected_id = encode_identifier_octets
          real_id = der[0, expected_id.size]
          if real_id == expected_id
            @matched_tag = tag
            return true
          end
        end
        @id_value = original_id
        no_match(der)
      end

      def no_match(der)
        if optional?
          @no_value = true
          @value = void_value
        elsif !@default.nil?
          @value = @default
        else
          raise_id_error(der)
        end
        false
      end

      def value_to_der
        case @value
        when Array
          @value.map(&:to_der).join
        else
          @value.to_s
        end
      end

      def explicit_type
        opts = { name: name, value: @value }
        if @accepted_tags.length == 1
          opts[:tag] = @accepted_tags.first
        elsif @accepted_tags.length > 1
          opts[:tag] = @accepted_tags
        end
        opts[:any_private] = true if @any_private
        opts[:class] = @asn1_class unless @asn1_class == :universal
        self.class.new(opts)
      end
    end
  end
end
