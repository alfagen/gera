# frozen_string_literal: true

module Gera
  class ExmoRatesJob < ApplicationJob
    include AutoLogger
    include RatesJob

    private

    def rate_source
      @rate_source ||= Gera::RateSourceExmo.get!
    end

    def load_rates
      Gera::ExmoFetcher.new.perform
    end

    def rate_keys
      { buy: 'buy_price', sell: 'sell_price' }
    end
  end
end
