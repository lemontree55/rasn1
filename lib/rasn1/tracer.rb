# frozen_string_literal: true

module RASN1
  # @private
  class Tracer
    # @return [IO]
    attr_reader :io
    # @return [Integer]
    attr_accessor :tracing_level

    TRACED_CLASSES = [Types::Any, Types::Choice, Types::Sequence, Types::SequenceOf, Types::Base].freeze

    # @param [IO] io
    def initialize(io)
      @io = io
      @tracing_level = 0
    end

    # Puts +msg+ onto {#io}.
    # @param [String] msg
    # @return [void]
    def trace(msg)
      @io.puts(indent << msg)
    end

    # Return identation for given +level+. If +nil+, use {#tracing_level}.
    # @param [Integer,nil] level
    # @return [String]
    def indent(level=nil)
      level ||= @tracing_level
      '  ' * level
    end
  end

  # Trace RASN1 parsing to +io+.
  # All parsing methods called in block are traced to +io+. Each ASN.1 element is
  # traced in a line showing element's id, its length and its data.
  # @param [IO] io
  # @example
  #   RASN1.trace do
  #     RASN1.parse("\x02\x01\x01")  # puts "INTEGER id: 2 (0x02), len: 1 (0x01), data: 0x01"
  #   end
  #   RASN1.parse("\x01\x01\xff")    # puts nothing onto STDOUT
  # @return [void]
  def self.trace(io=$stdout)
    @tracer = Tracer.new(io)
    Tracer::TRACED_CLASSES.each(&:start_tracing)

    begin
      yield @tracer
    ensure
      Tracer::TRACED_CLASSES.reverse.each(&:stop_tracing)
      @tracer.io.flush
      @tracer = nil
    end
  end

  # @private
  def self.tracer
    @tracer
  end

  module Types
    class Base
      class << self
        # @private
        # Patch {#do_parse} to add tracing ability
        def start_tracing
          alias_method :do_parse_without_tracing, :do_parse
          alias_method :do_parse, :do_parse_with_tracing
          alias_method :do_parse_explicit_without_tracing, :do_parse_explicit
          alias_method :do_parse_explicit, :do_parse_explicit_with_tracing
        end

        # @private
        # Unpatch {#do_parse} to remove tracing ability
        def stop_tracing
          alias_method :do_parse, :do_parse_without_tracing # rubocop:disable Lint/DuplicateMethods
          alias_method :do_parse_explicit, :do_parse_explicit_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      # @private
      # Parse +der+ with tracing abillity
      # @see #parse!
      def do_parse_with_tracing(der, ber)
        ret = do_parse_without_tracing(der, ber)
        RASN1.tracer.trace(self.trace)
        ret
      end

      def do_parse_explicit_with_tracing(data)
        RASN1.tracer.tracing_level += 1
        do_parse_explicit_without_tracing(data)
        RASN1.tracer.tracing_level -= 1
      end
    end

    class Choice
      class << self
        # @private
        # Patch {#parse!} to add tracing ability
        def start_tracing
          alias_method :parse_without_tracing, :parse!
          alias_method :parse!, :parse_with_tracing
        end

        # @private
        # Unpatch {#parse!} to remove tracing ability
        def stop_tracing
          alias_method :parse!, :parse_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      # @private
      # Parse +der+ with tracing abillity
      # @see #parse!
      def parse_with_tracing(der, ber: false)
        RASN1.tracer.trace(self.trace)
        parse_without_tracing(der, ber: ber)
      end
    end

    class Sequence
      class << self
        # @private
        # Patch {#der_to_value} to add tracing ability
        def start_tracing
          alias_method :der_to_value_without_tracing, :der_to_value
          alias_method :der_to_value, :der_to_value_with_tracing
        end

        # @private
        # Unpatch {#der_to_value!} to remove tracing ability
        def stop_tracing
          alias_method :der_to_value, :der_to_value_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      # @private
      # der_to_value +der+ with tracing abillity
      def der_to_value_with_tracing(der, ber: false)
        RASN1.tracer.tracing_level += 1
        der_to_value_without_tracing(der, ber: ber)
        RASN1.tracer.tracing_level -= 1
      end
    end

    class SequenceOf
      class << self
        # @private
        # Patch {#der_to_value} to add tracing ability
        def start_tracing
          alias_method :der_to_value_without_tracing, :der_to_value
          alias_method :der_to_value, :der_to_value_with_tracing
        end

        # @private
        # Unpatch {#der_to_value!} to remove tracing ability
        def stop_tracing
          alias_method :der_to_value, :der_to_value_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      # @private
      # der_to_value +der+ with tracing abillity
      def der_to_value_with_tracing(der, ber: false)
        RASN1.tracer.tracing_level += 1
        der_to_value_without_tracing(der, ber: ber)
        RASN1.tracer.tracing_level -= 1
      end
    end
  end
end
