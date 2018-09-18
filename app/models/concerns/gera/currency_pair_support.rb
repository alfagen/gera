module Gera
  module CurrencyPairSupport
    extend ActiveSupport::Concern

    included do
      if ancestors.include? ActiveRecord::Base
        scope :by_currency_pair, -> (pair) { where cur_from: pair.cur_from.to_s, cur_to: pair.cur_to.to_s }

        def self.find_by_currency_pair(pair)
          by_currency_pair(pair).take
        end

        def self.find_or_build_by_currency_pair(pair)
          by_currency_pair(pair).take || new(currency_pair: pair)
        end
      end
    end

    def currency_pair=(value)
      self.cur_from = value.cur_from
      self.cur_to = value.cur_to
      @currency_pair = nil
      @currency_from = nil
      @currency_to = nil
      value
    end

    def currency_pair
      @currency_pair ||= Gera::CurrencyPair.new currency_from, currency_to
    end

    def currency_from
      @currency_from ||= cur_from.is_a?(Money::Currency) ? cur_from : Money::Currency.find!(cur_from)
    end

    def currency_to
      @currency_to ||= cur_to.is_a?(Money::Currency) ? cur_to : Money::Currency.find!(cur_to)
    end
  end
end
