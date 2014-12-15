# encoding: utf-8
require "connection_pool"

module Moped
  class Connection

    # Provides common behavior around connection pooling for nodes.
    #
    # @since 2.0.2
    module Poolable

      # The default max size for the connection pool.
      POOL_SIZE = 5

      # The default timeout for getting connections from the queue.
      TIMEOUT = 0.5

      # Get a connection pool for the provided node.
      #
      # @example Get a connection pool for the node.
      #   node.pool
      #
      # @return [ Pool ] The connection pool for the Node.
      #
      # @since 2.0.2
      def pool
        @mutex.synchronize do
          @pool ||= create_pool
        end
      end

      def shutdown_pool
        @shutdown_mutex.synchronize do 
          return if !!@shutting_down
          Moped.logger.debug("MOPED: Shutting down connection pool for #{self.inspect}")
          @shutting_down = true
          @mutex.synchronize do  
            old_pool = @pool 
            @pool = nil
          end
        end

        begin
          if old_pool
            old_pool.shutdown {|conn| conn.disconnect }
          end
        ensure
          @shutting_down = false
        end

      end

      private

      def initialize(*args)
        super
        @mutex = Mutex.new
        @shutdown_mutex = Mutex.new
      end

      # Create a new connection pool for the provided node.
      #
      # @api private
      #
      # @example Get a connection pool for the node.
      #   node.create_pool
      #
      #
      # @return [ ConnectionPool ] A connection pool.
      #
      # @since 2.0.2
      def create_pool
        Moped.logger.debug("MOPED: Creating new connection pool for #{self.inspect}")        

        ConnectionPool.new(
          size: self.options[:pool_size] || POOL_SIZE,
          timeout: self.options[:pool_timeout] || TIMEOUT
        ) do
          Connection.new(
            self.address.ip,
            self.address.port,
            self.options[:timeout] || Connection::TIMEOUT,
            self.options
          )
        end
      end

    end
  end
end
