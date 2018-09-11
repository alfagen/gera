module GERA
  class RateSourceCBR < RateSource
    SUPPORTED_CURRENCIES = %i(rub kzt usd eur)

    def self.available_pairs
      [ 'KZT/RUB', 'USD/RUB', 'EUR/RUB' ].map { |cp| CryptoMath::CurrencyPair.new cp }.freeze
    end
  end
end
