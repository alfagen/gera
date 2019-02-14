# frozen_string_literal: true

module Gera
  class RateSourceEXMO < RateSource
    def self.supported_currencies
      %i[BTC BCH DSH ETH ETC LTC XRP XMR USD RUB ZEC EUR].map { |m| Money::Currency.find! m }
    end
  end
end
