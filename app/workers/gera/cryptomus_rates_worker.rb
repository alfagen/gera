# frozen_string_literal: true

module Gera
  class CryptomusRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    private

    def rate_source
      @rate_source ||= Gera::RateSourceCryptomus.get!
    end

    def load_rates
      Gera::CryptomusFetcher.new.perform
    end

    def rate_keys
      { buy: 'course', sell: 'course' }
    end
  end
end
