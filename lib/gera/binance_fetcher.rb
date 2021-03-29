require 'uri'
require 'net/http'
require 'rest-client'
require 'virtus'

module Gera
  class BinanceFetcher
    API_URL = 'https://api.binance.com/api/v3/ticker/24hr'

    def perform
      data.each_with_object({}) do |pair_data, ag|
        symbol = pair_data['symbol']

        cur_from = find_cur_from(symbol)
        next unless cur_from

        cur_to = find_cur_to(symbol, cur_from)
        next unless cur_to

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        ag[pair] = pair_data
      end
    end

    private

    def find_cur_from(symbol)
      RateSourceBinance.supported_currencies.find { |currency| symbol.start_with?(currency.to_s) }
    end

    def find_cur_to(symbol, cur_from)
      Money::Currency.find(symbol.split(cur_from.to_s).last)
    end

    def data
      response = RestClient::Request.execute url: API_URL, method: :get, verify_ssl: false

      raise response.code unless response.code == 200
      JSON.parse response.body
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
