# frozen_string_literal: true

module Gera
  # Import rates from Binance
  #
  class BinanceRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceBinance.get!
    end

    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data['askPrice'], buy_price: data['bidPrice']
    end

    def load_rates
      BinanceFetcher.new.perform
    end
  end
end
