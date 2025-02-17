# frozen_string_literal: true

module Gera
  # Import rates from FF (Fixed)
  #
  class FfFixedRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    private

    def rate_source
      @rate_source ||= RateSourceFfFixed.get!
    end

    def save_rate(pair, data)
      create_external_rates pair, data, sell_price: data[:out], buy_price: data[:out]
    end

    def load_rates
      FfFixedFetcher.new.perform
    end
  end
end
