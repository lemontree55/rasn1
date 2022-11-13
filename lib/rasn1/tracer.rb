# frozen_string_literal: true

module RASN1
  class Tracer
    def initialize(io)
      @io = io
    end

    def trace(msg)
      @io.puts(msg)
    end
  end

  def self.trace(io=$stdout)
    @tracer = Tracer.new(io)
    [Types::Any, Types::Base].each(&:start_tracing)

    begin
      yield @tracer
    ensure
      [Types::Base, Types::Any].each(&:stop_tracing)
      @tracer = nil
    end
  end

  def self.trace_message
    yield @tracer
  end

  module Types
    class Base
      class << self
        def start_tracing
          alias_method :do_parse_without_tracing, :do_parse
          alias_method :do_parse, :do_parse_with_tracing
        end

        def stop_tracing
          alias_method :do_parse, :do_parse_without_tracing # rubocop:disable Lint/DuplicateMethods
        end
      end

      def do_parse_with_tracing(der, ber)
        ret = do_parse_without_tracing(der, ber)
        RASN1.trace_message do |tracer|
          tracer.trace(self.trace)
        end
        ret
      end
    end
  end
end
