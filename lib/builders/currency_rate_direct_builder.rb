require_relative 'currency_rate_builder'

module Gera
  class CurrencyRateDirectBuilder < CurrencyRateBuilder
    attribute :source #, RateSource

    private

    def build
      raise Error, "Источником (#{source}) валюта #{currency_pair.cur_from} не поддерживается" unless source.is_currency_supported? currency_pair.cur_from
      raise Error, "Источником (#{source}) валюта #{currency_pair.cur_to} не поддерживается" unless source.is_currency_supported? currency_pair.cur_to

      external_rate = source.find_rate_by_currency_pair currency_pair

      raise Error, "В источнике (#{source}) не найден курс для #{currency_pair}" unless external_rate.present?

      CurrencyRate.new(
        currency_pair: currency_pair,
        rate_value: external_rate.rate_value,
        rate_source: source,
        mode: :direct,
        external_rate_id: external_rate.id
      )
    end
  end
end
