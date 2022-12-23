# frozen_string_literal: true

require 'uri'
require 'net/http'

module Gera
  class ExmoFetcher
    URL = 'https://api.exmo.me/v1/ticker/' # https://api.exmo.com/v1/ticker/
    Error = Class.new StandardError

    def perform
      raw_rates = load_rates.to_a
      rates = {}
      raw_rates.each do |currency_pair_keys, rate|
        currency_from, currency_to = find_currencies(currency_pair_keys)
        next if currency_from.nil? || currency_to.nil?

        currency_pair = Gera::CurrencyPair.new(cur_from: currency_from, cur_to: currency_to)
        rates[currency_pair] = rate
      end

      rates
    end

    private

    def find_currencies(currency_pair_keys)
      currency_key_from, currency_key_to = split_currency_pair_keys(currency_pair_keys)
      [find_currency(currency_key_from), find_currency(currency_key_to)]
    end

    def split_currency_pair_keys(currency_pair_keys)
      currency_pair_keys.split('_') .map { |c| c == 'DASH' ? 'DSH' : c }
    end

    def find_currency(key)
      Money::Currency.find(key)
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
