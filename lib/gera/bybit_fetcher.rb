# frozen_string_literal: true

require 'rest-client'

module Gera
  class BybitFetcher
    API_URL = 'https://api2.bytick.com/fiat/otc/item/online'
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
      response = RestClient::Request.execute(
        url: API_URL,
        method: :post,
        payload: params.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Host' => 'api2.bytick.com'
        },
        verify_ssl: true
      )

      raise Error, "HTTP #{response.code}" unless response.code == 200

      items = JSON.parse(response.body).dig('result', 'items')
      rate = items[2] || items[1] || raise(Error, 'No rates')

      [rate]
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
      @supported_currencies ||= RateSourceBybit.supported_currencies
    end
  end
end
