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

        next if price_is_missed?(rate: rate)

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate
      end
    end

    private

    # NOTE: for some pairs price is "0.00000000"
    def price_is_missed?(rate:)
      rate['askPrice'].to_f.zero? || rate['bidPrice'].to_f.zero?
    end

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

    def currency_name(currency)
      name = currency.to_s
      name = 'DASH' if name == 'DSH'
      name
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
