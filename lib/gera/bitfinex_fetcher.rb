# frozen_string_literal: true

require 'rest-client'

module Gera
  class BitfinexFetcher
    API_URL = 'https://api-pub.bitfinex.com/v2/tickers?symbols=ALL'

    def perform
      rates.each_with_object({}) do |rate, memo|
        symbol = rate[0]

        cur_from = find_cur_from(symbol)
        next unless cur_from

        cur_to = find_cur_to(symbol, cur_from)
        next unless cur_to

        next if price_is_missed?(rate: rate)

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate
      end
    end

    private

    def rates
      response = RestClient::Request.execute url: API_URL, method: :get, verify_ssl: true

      raise response.code unless response.code == 200
      JSON.parse response.body
    end

    def supported_currencies
      @supported_currencies ||= RateSourceBitfinex.supported_currencies
    end

    def find_cur_from(symbol)
      supported_currencies.find do |currency|
        symbol.start_with?("t#{currency}")
      end
    end

    def find_cur_to(symbol, cur_from)
      Money::Currency.find(symbol.split("t#{cur_from}").last)
    end

    def price_is_missed?(rate:)
      rate[7].to_f.zero?
    end
  end
end
