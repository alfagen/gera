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
      create_external_rates pair, data, sell_price: data['highPrice'], buy_price: data['lowPrice']
    end

    def load_rates
      RateSourceBinance.available_pairs.each_with_object({}) { |pair, ag| ag[pair] = ::BinanceFetcher.new(pair: pair).perform }
    end
  end
end
