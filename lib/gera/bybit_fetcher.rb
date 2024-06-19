# frozen_string_literal: true

require 'rest-client'

module Gera
  class BybitFetcher < PaymentServices::Base::Client
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
      buy_rate, sell_rate = rate(type: '1'), rate(type: '0')

      buy_rate['buy'] = buy_rate['price'].to_f
      buy_rate['sell'] = sell_rate['price'].to_f

      [buy_rate]
    end

    def rate(type:)
      items = safely_parse(http_request(
        url: API_URL,
        method: :POST,
        body: params(type: type).to_json,
        headers: build_headers
      )).dig('result', 'items')

      final_rate = items[2] || items[1] || raise(Error, 'No rates')

      final_rate
    end

    def 

    def params(type:)
      { 
        userId: '',
        tokenId: 'USDT',
        currencyId: 'RUB',
        payment: ['75', '377', '582', '581'],
        side: type,
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
        'Content-Type'   => 'application/json',
        'Host'           => 'api2.bytick.com',
        'Content-Length' => '182'
      }
    end
  end
end
