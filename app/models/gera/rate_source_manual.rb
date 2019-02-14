# frozen_string_literal: true

module Gera
  class RateSourceManual < RateSource
    def self.supported_currencies
      Money::Currency.all
    end

    def self.available_pairs
      CurrencyPair.all
    end
  end
end
