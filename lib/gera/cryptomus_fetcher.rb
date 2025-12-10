# frozen_string_literal: true

require 'rest-client'

module Gera
  class CryptomusFetcher
    API_URL = 'https://api.cryptomus.com/v1/exchange-rate'
    Error = Class.new StandardError

    def perform
      rates.each_with_object({}) do |rate, memo|
        cur_from, cur_to = rate['from'], rate['to']
        cur_from = 'DSH' if cur_from == 'DASH'
        cur_to = 'DSH' if cur_to == 'DASH'
        next unless supported_currencies.include?(cur_to)

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate
      end
    end

    private

    def rates
      data = supported_currencies.map(&:iso_code).map { |code| rate(currency: code) }.flatten.filter { |rate| rate['from'] != rate['to'] }
      unique_pairs = Set.new
      filtered_data = data.reverse.select do |hash|
        pair = [hash['from'], hash['to']].sort
        unique_pairs.add?(pair) ? true : false
      end
      filtered_data
    end

    def rate(currency:)
      currency = 'DASH' if currency == 'DSH'

      response = RestClient::Request.execute(
        url: "#{API_URL}/#{currency}/list",
        method: :get,
        headers: { 'Content-Type' => 'application/json' },
        verify_ssl: true
      )

      raise Error, "HTTP #{response.code}" unless response.code == 200

      JSON.parse(response.body).dig('result')
    end

    def supported_currencies
      @supported_currencies ||= RateSourceCryptomus.supported_currencies
    end
  end
end
