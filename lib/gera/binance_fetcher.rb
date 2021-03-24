require 'uri'
require 'net/http'
require 'rest-client'
require 'virtus'

module Gera
  class BinanceFetcher
    API_URL = 'https://api.binance.com/api/v3/ticker/24hr'

    include Virtus.model strict: true

    attribute :pair, Object

    def perform
      response = RestClient::Request.execute url: url, method: :get, verify_ssl: false

      raise response.code unless response.code == 200
      JSON.parse response.body
    end

    private

    def url
      "#{API_URL}?symbol=#{pair.cur_from.to_s + pair.cur_to.to_s}"
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
