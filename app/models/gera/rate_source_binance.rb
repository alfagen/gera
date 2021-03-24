# frozen_string_literal: true

module Gera
  class RateSourceBinance < RateSource
    def self.supported_currencies
      %i[XMR XEM NEO EOS ADA WAVES].map { |m| Money::Currency.find! m }
    end
  end
end
