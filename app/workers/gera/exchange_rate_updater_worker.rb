# frozen_string_literal: true

module Gera
  class ExchangeRateUpdaterWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :exchange_rates

    LOGGER = Logger.new(File.expand_path("~/admin.kassa.cc/current/log/operator_exchange_rates_api.log"))

    def perform(exchange_rate_id, attributes, timestamp = nil)
      ExchangeRate.find(exchange_rate_id).update(attributes)
      LOGGER.info("#manual#: after update #{exchange_rate_id} - #{timestamp} - #{Time.current.to_i}") unless timestamp.nil?
    end
  end
end
