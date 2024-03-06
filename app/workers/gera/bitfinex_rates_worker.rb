# frozen_string_literal: true

module Gera
  # Import rates from Bitfinex
  #
  class BitfinexRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    prepend RatesWorker

    # sidekiq_options lock: :until_executed

    private

    def rate_source
      @rate_source ||= RateSourceBitfinex.get!
    end

    # ["tXMRBTC", 0.0023815, 1026.97384923, 0.0023839, 954.7667526, -0.0000029, -0.00121619, 0.0023816, 3944.20608752, 0.0024229, 0.0022927]
    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data[7], buy_price: data[7]
    end

    def load_rates
      BitfinexFetcher.new.perform
    end
  end
end
