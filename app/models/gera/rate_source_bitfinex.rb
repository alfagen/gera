module GERA
  class RateSourceBitfinex < RateSource
    def self.supported_currencies
      %i(NEO BTC ETH EUR USD).map { |m| Money::Currency.find! m }
    end
  end
end
