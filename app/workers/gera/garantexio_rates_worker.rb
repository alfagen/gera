# frozen_string_literal: true

module Gera
  class GarantexioRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= Gera::RateSourceGarantexio.get!
    end

    def load_rates
      Gera::GarantexioFetcher.new.perform
    end

    def rate_keys
      { buy: 'last_price', sell: 'last_price' }
    end
  end
end
