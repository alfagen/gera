module GERA
  class RateSourceBitfinex < RateSource
    SUPPORTED_CURRENCIES = %i(NEO BTC ETH EUR USD)

    def self.available_pairs
      generate_pairs_from_currencies SUPPORTED_CURRENCIES
    end
  end
end
