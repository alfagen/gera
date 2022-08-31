# frozen_string_literal: true

module Gera
  class ExchangeRateUpdaterWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :exchange_rates

    def perform(exchange_rate_id, attributes:)
      ExchangeRate.find(exchange_rate_id).update!(attributes)
    end
  end
end
