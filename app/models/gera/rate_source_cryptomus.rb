# frozen_string_literal: true

module Gera
  class RateSourceCryptomus < RateSource
    def self.supported_currencies
      %i[RUB USD BTC LTC ETH DSH KZT XMR BCH EUR USDT UAH TRX DOGE BNB TON UZS AZN BYN SOL USDC TRY MATIC].map { |m| Money::Currency.find! m }
    end
  end
end
