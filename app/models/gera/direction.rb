# frozen_string_literal: true

module Gera
  # Exchange Direction
  #
  class Direction
    include Virtus.model

    attribute :ps_from # , PaymentSystem
    attribute :ps_to   # , PaymentSystem

    alias_attribute :payment_system_from, :ps_from
    alias_attribute :payment_system_to, :ps_to
    alias_attribute :income_payment_system, :ps_from
    alias_attribute :outcome_payment_system, :ps_to

    delegate :id, to: :ps_to, prefix: true
    delegate :id, to: :ps_from, prefix: true

    def currency_from
      payment_system_from.currency
    end

    def currency_to
      payment_system_to.currency
    end

    def inspect
      to_s
    end

    def to_s
      "direction:#{payment_system_from.try(:id) || '???'}-#{payment_system_to.try(:id) || '???'}"
    end

    def exchange_rate
      Universe.exchange_rates_repository.find_by_direction self
    end

    def direction_rate
      Universe.direction_rates_repository.find_by_direction self
    end
  end
end
