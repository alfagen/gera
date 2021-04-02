# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'rest-client'
require 'virtus'

module Gera
  class BinanceFetcher
    API_URL = 'https://api.binance.com/api/v3/ticker/bookTicker'

    def perform
      rates.each_with_object({}) do |rate, memo|
        symbol = rate['symbol']

        cur_from = find_cur_from(symbol)
        next unless cur_from

        cur_to = find_cur_to(symbol, cur_from)
        next unless cur_to

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate
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
        currency_name = currency.to_s
        currency_name = 'DASH' if currency_name == 'DSH'

        symbol.start_with?(currency_name)
      end
    end

    def find_cur_to(symbol, cur_from)
      Money::Currency.find(symbol.split(cur_from.to_s).last)
    end

    def supported_currencies
      @supported_currencies ||= RateSourceBinance.supported_currencies
    end

    def http
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http
      end
    end
  end
end
