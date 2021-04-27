# frozen_string_literal: true

module Gera
  class RateSourceBinance < RateSource
    def self.supported_currencies
      %i[BTC BCH DSH ETH ETC LTC XRP XMR ZEC NEO EOS ADA XEM WAVES TRX DOGE BNB].map { |m| Money::Currency.find! m }
    end
  end
end
