# frozen_string_literal: true

require 'uri'
require 'net/http'

module Gera
  class ExmoFetcher
    URL = 'https://api.exmo.me/v1/ticker/' # https://api.exmo.com/v1/ticker/

    def perform
      raw_rates = load_rates.to_a
      rates = {}
      raw_rates.each do |currency_pair_keys, rate|
        currency_key_from, currency_key_to = split_currency_pair_keys(currency_pair_keys)
        currency_from = find_currency(currency_key_from)
        currency_to = find_currency(currency_key_to)
        next if currency_from.nil? || currency_to.nil?

        currency_pair = Gera::CurrencyPair.new(cur_from: currency_from, cur_to: currency_to)
        rates[currency_pair] = rate
      end

      rates
    end

    private

    def split_currency_pair_keys(currency_pair_keys)
      currency_pair_keys.split('_') .map { |c| c == 'DASH' ? 'DSH' : c }
    end

    def find_currency(currency_key)
      currency = Money::Currency.find(currency_key)
      logger.warn "Not supported currency #{currency_key}" if currency.nil?
      currency
    end

    def load_rates
      url = URI.parse(URL)
      result = JSON.parse(open(url).read)
      raise Error, 'Result is not a hash' unless result.is_a?(Hash)
      raise Error, result['error'] if result['error'].present?

      result
    end
  end
end
