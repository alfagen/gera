module GERA
  class RateSourceManual < RateSource
    def supported_currencies
      Money::Currency.all
    end

    def self.available_pairs
      CurrencyPair.all
    end
  end
end
