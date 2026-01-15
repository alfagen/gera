# frozen_string_literal: true

module Gera
  class CryptomusRatesJob < ApplicationJob
    include AutoLogger
    include RatesJob

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
