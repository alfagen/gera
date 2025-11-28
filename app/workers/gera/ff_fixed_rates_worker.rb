# frozen_string_literal: true

module Gera
  class FfFixedRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= Gera::RateSourceFfFixed.get!
    end

    def load_rates
      Gera::FfFixedFetcher.new.perform
    end

    def rate_keys
      { buy: 'out', sell: 'out' }
    end
  end
end
