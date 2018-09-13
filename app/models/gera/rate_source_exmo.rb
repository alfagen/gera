module GERA
  class RateSourceEXMO < RateSource
    def self.supported_currencies
      %i(BTC BCH DSH ETH ETC LTC XRP XMR USD RUB ZEC EUR).map { |m| Money::Currency.find! m }
    end
  end
end
