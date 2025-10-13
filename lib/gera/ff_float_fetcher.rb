# frozen_string_literal: true

module Gera
  class FfFloatFetcher
    API_URL = 'https://ff.io/rates/float.xml'
    Error = Class.new(StandardError)

    def perform
      result = {}
      raw_rates = rates

      raw_rates.each do |raw_rate|
        rate = raw_rate.transform_keys(&:to_s)

        cur_from = rate['from']
        cur_to   = rate['to']

        cur_from = 'BNB' if cur_from == 'BSC'
        cur_to   = 'BNB' if cur_to == 'BSC'

        next unless supported_currencies.include?(cur_from)
        next unless supported_currencies.include?(cur_to)

        pair         = Gera::CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        reverse_pair = Gera::CurrencyPair.new(cur_from: cur_to, cur_to: cur_from)

        result[pair] = rate unless result.key?(reverse_pair)
      end

      result
    end

    private

    def rates
      xml_data = URI.open(API_URL).read
      doc = Nokogiri::XML(xml_data)

      doc.xpath('//item').map do |item|
        {
          from: item.at('from')&.text,
          to: item.at('to')&.text,
          in: item.at('in')&.text.to_f,
          out: item.at('out')&.text.to_f,
          amount: item.at('amount')&.text.to_f,
          tofee: item.at('tofee')&.text,
          minamount: item.at('minamount')&.text,
          maxamount: item.at('maxamount')&.text
        }
      end
    end

    def supported_currencies
      @supported_currencies ||= RateSourceFfFixed.supported_currencies
    end
  end
end
