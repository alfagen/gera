# frozen_string_literal: true

module Gera
  # Import rates from Garantexio
  #
  class GarantexioRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceGarantexio.get!
    end

    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data['last_price'], buy_price: data['last_price']
    end

    def load_rates
      GarantexioFetcher.new.perform
    end
  end
end
