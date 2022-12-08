require_relative 'currency_rate_builder'

module Gera
  class CurrencyRateAutoBuilder < CurrencyRateBuilder
    private

    def build
      build_same ||
        build_from_sources ||
        build_cross ||
        raise(Error, "Не найден автоматический способ расчета")
    end

    def build_from_sources
      RateSource.enabled.ordered.each do |rate_source|
        result = build_from_source(rate_source)
        return result if result.present?
      end

      nil
    end

    def build_cross
      result = CurrencyRateCrossBuilder.new(currency_pair: currency_pair).build_currency_rate
      raise result.error if result.error?
      result.currency_rate
    end

    def build_from_source(source)
      CurrencyRateDirectBuilder.new(currency_pair: currency_pair, source: source).build_currency_rate.currency_rate
    end

    def build_same
      CurrencyRate.new(currency_pair: currency_pair, rate_value: 1, mode: :same) if currency_pair.same?
    end
  end
end
