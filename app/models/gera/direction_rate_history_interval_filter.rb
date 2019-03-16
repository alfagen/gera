# frozen_string_literal: true

module Gera
  class DirectionRateHistoryIntervalFilter
    include Virtus.model strict: true
    include ActiveModel::Conversion
    extend  ActiveModel::Naming
    include ActiveModel::Validations

    attribute :payment_system_from_id, Integer, default: ->(_a, _b) { Gera::PaymentSystem.first.id }
    attribute :payment_system_to_id, Integer, default: ->(_a, _b) { Gera::PaymentSystem.first.id }
    attribute :value_type, String, default: 'rate'

    def payment_system_from
      @payment_system_from ||= Gera::PaymentSystem.find payment_system_from_id
    end

    def payment_system_to
      @payment_system_to ||= Gera::PaymentSystem.find payment_system_to_id
    end

    def to_param
      to_hash
    end

    def persisted?
      false
    end
  end
end
