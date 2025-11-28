# frozen_string_literal: true

module Gera
  class FfFloatRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= Gera::RateSourceFfFloat.get!
    end

    def load_rates
      Gera::FfFloatFetcher.new.perform
    end

    def rate_keys
      { buy: 'out', sell: 'out' }
    end
  end
end
