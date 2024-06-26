# frozen_string_literal: true

module Gera
  # Import rates from Binance
  #
  class BinanceRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    sidekiq_options lock: :until_executed

    private

    def rate_source
      @rate_source ||= RateSourceBinance.get!
    end

    def save_rate(currency_pair, data)
      create_external_rates(currency_pair, data, sell_price: data['askPrice'], buy_price: data['bidPrice'])
    end

    def load_rates
      BinanceFetcher.new.perform
    end
  end
end
