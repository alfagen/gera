# frozen_string_literal: true

module Gera
  # Import rates from Bybit
  #
  class BybitRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= Gera::RateSourceBybit.get!
    end

    def load_rates
      Gera::BybitFetcher.new.perform
    end

    def rate_keys
      { buy: 'price', sell: 'price' }
    end
  end
end
