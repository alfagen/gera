# frozen_string_literal: true

module Gera
  class ExchangeRateUpdaterWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :exchange_rates

    def perform(exchange_rate_id, attributes, timestamp = nil)
      logger = Logger.new("#{Rails.root}/log/operator_exchange_rates_api.log")
      ExchangeRate.find(exchange_rate_id).update(attributes)
      logger.info("#manual#: after update #{exchange_rate.id} - #{timestamp} - #{Time.current.to_i}") unless timestamp.nil?
    end
  end
end
