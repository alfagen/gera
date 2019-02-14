# frozen_string_literal: true

module Gera
  # Базовый курс
  class CurrencyRate < ApplicationRecord
    include CurrencyPairSupport
    include Authority::Abilities

    self.table_name = 'currency_rates'

    belongs_to :snapshot, class_name: 'Gera::CurrencyRateSnapshot'
    belongs_to :external_rate, optional: true
    belongs_to :rate_source, optional: true

    belongs_to :external_rate1, class_name: 'Gera::ExternalRate', optional: true
    belongs_to :external_rate2, class_name: 'Gera::ExternalRate', optional: true
    belongs_to :external_rate3, class_name: 'Gera::ExternalRate', optional: true

    scope :by_exchange_rate, ->(er) { by_currency_pair er.currency_pair }

    enum mode: %i[direct inverse same cross], _prefix: true

    before_save do
      raise("У кросс-курса (#{currency_pair}) должно быть несколько external_rates (#{external_rates.count})") if mode_cross? && !external_rates.many?

      self.metadata ||= {}
    end

    def external_rates=(rates)
      self.external_rate, self.external_rate1, self.external_rate2, self.external_rate3 = rates
    end

    def external_rates
      [external_rate, external_rate1, external_rate2, external_rate3].compact
    end

    def to_s
      currency_pair.to_s
    end

    def inspect
      "#{currency_pair}:#{humanized_rate}"
    end

    def rate_money
      Money.from_amount(rate_value, cur_to)
    end

    def reverse_rate_money
      Money.from_amount(1.0 / rate_value, cur_from)
    end

    def humanized_rate
      if rate_value < 1
        "#{rate_value} (1/#{1.0 / rate_value})"
      else
        rate_value
      end
    end

    def dump
      as_json(only: %i[created_at cur_from cur_to mode rate_value metadata rate_source_id]).merge external_rates: external_rates.map(&:dump)
    end

    def meta
      @meta ||= OpenStruct.new metadata.deep_symbolize_keys
    end
  end
end
