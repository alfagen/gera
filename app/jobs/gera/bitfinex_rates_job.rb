# frozen_string_literal: true

module Gera
  # Import rates from Bitfinex
  #
  class BitfinexRatesJob < ApplicationJob
    include AutoLogger
    include RatesJob

    private

    def rate_source
      @rate_source ||= Gera::RateSourceBitfinex.get!
    end

    def load_rates
      Gera::BitfinexFetcher.new.perform
    end

    # ["tXMRBTC", 0.0023815, 1026.97384923, 0.0023839, 954.7667526, -0.0000029, -0.00121619, 0.0023816, 3944.20608752, 0.0024229, 0.0022927]

    def rate_keys
      { buy: 7, sell: 7 }
    end
  end
end
