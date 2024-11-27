# frozen_string_literal: true

module Gera
  class ExchangeRateUpdaterWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :exchange_rates

    def perform(exchange_rate_id, attributes, log_id = nil)
      ExchangeRate.find(exchange_rate_id).update(attributes)
      ExchangeRateLog.find(log_id).touch unless log_id.nil?
    end
  end
end
