module GERA
  class RateSourceEXMO < RateSource
    SUPPORTED_CURRENCIES = %i(BTC BCH DSH ETH ETC LTC XRP XMR USD RUB ZEC EUR)

    def self.available_pairs
      generate_pairs_from_currencies SUPPORTED_CURRENCIES
    end
  end
end
