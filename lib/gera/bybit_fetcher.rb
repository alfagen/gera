# frozen_string_literal: true

require 'rest-client'

module Gera
  class BybitFetcher < PaymentServices::Base::Client
    API_URL = 'https://api2.bybit.com/fiat/otc/item/online'
    Error = Class.new StandardError

    def perform
      rates.each_with_object({}) do |rate, memo|
        cur_from, cur_to = rate['tokenId'], rate['currencyId']
        next unless supported_currencies.include?(cur_from) && supported_currencies.include?(cur_to)

        pair = CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        memo[pair] = rate
      end
    end

    private

    def rates
      items = safely_parse(http_request(
        url: API_URL,
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )).dig('result', 'items')
      items = JSON.parse(response.body).dig('result', 'items')
      rate = items[2] || items[1] || raise(Error, 'No rates')

      [item]
    end

    def params
      { 
        userId: '',
        tokenId: 'USDT',
        currencyId: 'RUB',
        payment: ['75', '377', '582', '581'],
        side: '1',
        size: '3',
        page: '1',
        amount: '',
        authMaker: false,
        canTrade: false
      }
    end

    def supported_currencies
      @supported_currencies ||= RateSourceGarantexio.supported_currencies
    end

    def build_headers
      {
        'Content-Type' => 'application/json'
      }
    end
  end
end
