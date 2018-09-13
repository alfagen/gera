require 'uri'
require 'net/http'
require 'rest-client'

module GERA
  class BitfinexFetcher
    API_URL = 'https://api.bitfinex.com/v1/pubticker/'

    include Virtus.model strict: true

    # Например btcusd
    attribute :ticker, String

    def perform
      response = RestClient::Request.execute url: url, method: :get, verify_ssl: false

      raise response.code unless response.code == 200
      JSON.parse response.body
    end

    private

    def url
      API_URL + ticker
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
