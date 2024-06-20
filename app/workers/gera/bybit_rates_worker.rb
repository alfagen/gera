# frozen_string_literal: true

module Gera
  # Import rates from Garantexio
  #
  class BybitRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceBybit.get!
    end

    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data['price'].to_f, buy_price: data['price'].to_f
    end

    def load_rates
      BybitFetcher.new.perform
    end
  end
end
