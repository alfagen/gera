module GERA
  class CurrencyRatesRepository
    UnknownPair = Class.new StandardError

    def snapshot
      @snapshot ||= CurrencyRateSnapshot.last || raise("Нет актуального snapshot-а")
    end

    def find_currency_rate_by_pair pair
      rates_by_pair[pair] || raise(UnknownPair, "Не найдена валютная пара #{pair} в базовых курсах")
    end

    def get_currency_rate_by_pair pair
      find_currency_rate_by_pair(pair)
    rescue UnknownPair
      CurrencyRate.new(currency_pair: pair).freeze
    end

    private

    def rates_by_pair
      @rates_by_pair ||= snapshot.rates.each_with_object({}) { |r,h| h[r.currency_pair] = r }
    end
  end
end
