# frozen_string_literal: true

module Gera
  class RabbitPublisher
    class << self
      def publish(queue, message = {})
        channel.default_exchange.publish(message.to_json, routing_key: queue)
        connection.close
      end

      def channel
        @channel ||= connection.create_channel
      end

      def connection
        @connection ||= Bunny.new.tap(&:start)
      end
    end
  end
end
