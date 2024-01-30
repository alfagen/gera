# frozen_string_literal: true

require 'rest-client'

module Gera
  class GarantexioFetcher
    API_URL = 'https://stage.garantex.biz/api/v2/coinmarketcap/ticker'

    def perform
      rates.each_with_object({}) do |rate, memo|
        symbol, rate_info = rate.keys[0], rate.values[0]
        cur_from, cur_to = symbol.split('_')
        next unless supported_currencies.include?(cur_from) && supported_currencies.include?(cur_to)

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate_info
      end
    end

    private

    def rates
      response = RestClient::Request.execute url: API_URL, method: :get, verify_ssl: false

      raise response.code unless response.code == 200
      JSON.parse response.body
    end

    def find_cur_from(symbol)
      supported_currencies.find do |currency|
        symbol.start_with?(currency_name(currency))
      end
    end

    def find_cur_to(symbol, cur_from)
      Money::Currency.find(symbol.split(currency_name(cur_from)).last)
    end

    def supported_currencies
      @supported_currencies ||= RateSourceGarantexio.supported_currencies
    end
  end
end
