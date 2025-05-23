# frozen_string_literal: true

module Gera
  class ExchangeRateUpdaterWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :exchange_rates

    def perform(exchange_rate_id, attributes)
      increment_exchange_rate_touch_metric
      ExchangeRate.find(exchange_rate_id).update(attributes)
    end

    private

    def increment_exchange_rate_touch_metric
      Yabeda.exchange.exchange_rate_touch_count.increment({
        action: 'update',
        source: 'Gera::ExchangeRateUpdaterWorker'
      })
    end
  end
end
