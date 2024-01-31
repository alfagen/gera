# frozen_string_literal: true

module Gera
  class RateSourceGarantexio < RateSource
    def self.supported_currencies
      %i[USDT BTC RUB].map { |m| Money::Currency.find! m }
    end
  end
end
