# frozen_string_literal: true

module Gera
  # Import rates from Garantexio
  #
  class CryptomusRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceCryptomus.get!
    end

    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data['course'], buy_price: data['course']
    end

    def load_rates
      CryptomusFetcher.new.perform
    end
  end
end
