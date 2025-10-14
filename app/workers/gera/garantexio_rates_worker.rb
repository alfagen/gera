# frozen_string_literal: true

module Gera
  class GarantexioRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceGarantexio.get!
    end

    def load_rates
      GarantexioFetcher.new.perform
    end

    def rate_keys
      { buy: 'last_price', sell: 'last_price' }
    end
  end
end
