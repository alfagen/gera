# frozen_string_literal: true

module Gera
  class CurrencyRateHistoryIntervalFilter
    include Virtus.model strict: true
    include ActiveModel::Conversion
    extend  ActiveModel::Naming
    include ActiveModel::Validations

    attribute :cur_from, String, default: ->(_a, _b) { Money::Currency.first }
    attribute :cur_to, String, default: ->(_a, _b) { Money::Currency.first }
    attribute :value_type, String, default: 'rate'

    def currency_from
      Money::Currency.find cur_from
    end

    def currency_to
      Money::Currency.find cur_to
    end

    def to_param
      to_hash
    end

    def persisted?
      false
    end
  end
end
