# frozen_string_literal: true

module Gera
  class BinanceRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    sidekiq_options lock: :until_executed

    private

    def rate_source
      @rate_source ||= RateSourceBinance.get!
    end

    def load_rates
      BinanceFetcher.new.perform
    end

    def rate_keys
      { buy: 'bidPrice', sell: 'askPrice' }
    end
  end
end
