# frozen_string_literal: true

module Gera
  class RateSourceBybit < RateSource
    def self.supported_currencies
      %i[USDT RUB].map { |m| Money::Currency.find! m }
    end
  end
end
