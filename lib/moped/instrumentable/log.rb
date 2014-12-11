# encoding: utf-8
module Moped
  module Instrumentable

    # Provides logging instrumentation for compatibility with active support
    # notifications.
    #
    # @since 2.0.0
    module Log
      extend self

      # Instrument the log payload.
      #
      # @example Instrument the log payload.
      #   Log.instrument("moped.ops", {})
      #
      # @param [ String ] name The name of the logging type.
      # @param [ Hash ] payload The log payload.
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 2.0.0
      def instrument(name, payload = {})
        started = Time.new
        begin
          yield if block_given?
          Moped::Loggable.log_operations(payload[:prefix], payload[:ops], runtime(started))
        rescue Exception => e
          payload[:exception] = [ e.class.name, e.message ]
          Moped::Loggable.warn(payload[:prefix],payload[:exception].join(' '),runtime(started))
          Moped::Loggable.log_operations(payload[:prefix], payload[:ops], runtime(started))
          raise e
        end
      end

      def runtime(started)
        ("%.4fms" % (1000 * (Time.now.to_f - started.to_f))) 
      end
    end
  end
end
