# frozen_string_literal: true

module Gera
  class FfFixedFetcher
    API_URL = 'https://ff.io/rates/fixed.xml'
    Error = Class.new StandardError

    def perform
      rates.each_with_object({}) do |rate, memo|
        cur_from, cur_to = rate[:from], rate[:to]
        next unless supported_currencies.include?(cur_from)
        next unless supported_currencies.include?(cur_to)

        pair = Gera::CurrencyPair.new(cur_from: cur_from, cur_to: cur_to)
        reverse_pair = Gera::CurrencyPair.new(cur_from: cur_to, cur_to: cur_from)

        memo[pair] = rate unless memo.key?(reverse_pair)
      end
    end

    private

    def rates
      xml_data = URI.open(API_URL).read
      doc = Nokogiri::XML(xml_data)
      res = []

      doc.xpath('//item').each do |item|
        rate_info = {
          from: item.at('from')&.text,
          to: item.at('to')&.text,
          in: item.at('in')&.text.to_f,
          out: item.at('out')&.text.to_f,
          amount: item.at('amount')&.text.to_f,
          tofee: item.at('tofee')&.text,
          minamount: item.at('minamount')&.text,
          maxamount: item.at('maxamount')&.text
        }
        res << rate_info
      end

      res
    end

    def supported_currencies
      @supported_currencies ||= RateSourceFfFixed.supported_currencies
    end
  end
end
