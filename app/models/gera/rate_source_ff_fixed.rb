# frozen_string_literal: true

module Gera
  class RateSourceFfFixed < RateSource
    def self.supported_currencies
      %i[BTC BCH DSH ETH ETC LTC XRP XMR ZEC NEO EOS ADA XEM WAVES TRX DOGE BNB XLM DOT USDT UNI LINK SOL USDC MATIC TON].map { |m| Money::Currency.find! m }
    end
  end
end
