# frozen_string_literal: true

module Gera
  class RateSourceCbr < RateSource
    def self.supported_currencies
      %i[RUB KZT USD EUR UAH UZS AZN].map { |m| Money::Currency.find! m }
    end

    def self.available_pairs
      ['KZT/RUB', 'USD/RUB', 'EUR/RUB', 'UAH/RUB', 'UZS/RUB', 'AZN/RUB'].map { |cp| Gera::CurrencyPair.new cp }.freeze
    end
  end
end
