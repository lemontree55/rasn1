# frozen_string_literal: true

module RASN1
  # @private
  class Tracer
    # @return [IO]
    attr_reader :io

    def initialize(io)
      @io = io
    end

    # Puts +msg+ onto {#io}.
    # @param [String] msg
    # @return [void]
    def trace(msg)
      @io.puts(msg)
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
    [Types::Any, Types::Choice, Types::Base].each(&:start_tracing)

    begin
      yield @tracer
    ensure
      [Types::Base, Types::Choice, Types::Any].each(&:stop_tracing)
      @tracer.io.flush
      @tracer = nil
    end
  end

  # @private
  def self.trace_message
    yield @tracer
  end

  module Types
    class Base
      class << self
        # @private
        # Patch {#do_parse} to add tracing ability
        def start_tracing
          alias_method :do_parse_without_tracing, :do_parse
          alias_method :do_parse, :do_parse_with_tracing
        end

        # @private
        # Unpatch {#do_parse} to remove tracing ability
        def stop_tracing
          alias_method :do_parse, :do_parse_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      # @private
      # Parse +der+ with tracing abillity
      # @see #parse!
      def do_parse_with_tracing(der, ber)
        ret = do_parse_without_tracing(der, ber)
        RASN1.trace_message do |tracer|
          tracer.trace(self.trace)
        end
        ret
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
        RASN1.trace_message do |tracer|
          tracer.trace(self.trace)
        end
        parse_without_tracing(der, ber: ber)
      end
    end
  end
end
