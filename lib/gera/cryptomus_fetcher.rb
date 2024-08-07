# frozen_string_literal: true

module Gera
  class CryptomusFetcher < PaymentServices::Base::Client
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
      supported_currencies.map(&:iso_code).map { |code| rate(currency: code) }.flatten
    end

    def rate(currency:)
      currency = 'DASH' if currency == 'DSH'

      safely_parse(http_request(
        url: "#{API_URL}/#{currency}/list",
        method: :GET,
        headers: build_headers
      )).dig('result')
    end

    def supported_currencies
      @supported_currencies ||= RateSourceCryptomus.supported_currencies
    end

    def build_headers
      {
        'Content-Type'   => 'application/json'
      }
    end
  end
end
