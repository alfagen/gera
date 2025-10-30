# frozen_string_literal: true

module Gera
  # Конечный курс
  # Finite direction rate
  class DirectionRate < ApplicationRecord
    include Mathematic
    include AutoLogger
    include DirectionSupport
    include Authority::Abilities
    include AliasAssociation

    UnknownExchangeRate = Class.new StandardError

    belongs_to :ps_from, class_name: 'Gera::PaymentSystem'
    belongs_to :ps_to, class_name: 'Gera::PaymentSystem'
    belongs_to :currency_rate, class_name: 'Gera::CurrencyRate'
    belongs_to :exchange_rate
    belongs_to :snapshot, class_name: 'Gera::DirectionRateSnapshot'

    before_validation do
      self.ps_from = exchange_rate.payment_system_from
      self.ps_to = exchange_rate.payment_system_to
    end

    before_validation :calculate_rate, unless: :finite_rate

    validates :base_rate_value, presence: true
    validates :rate_percent, presence: true
    validates :finite_rate, presence: true

    alias_association :payment_system_from, :ps_from
    alias_association :payment_system_to, :ps_to
    alias_association :income_payment_system, :ps_from
    alias_association :outcome_payment_system, :ps_to
    alias_attribute :income_payment_system_id, :ps_from_id
    alias_attribute :outcome_payment_system_id, :ps_to_id

    alias_attribute :comission, :rate_percent
    alias_attribute :finite_rate, :rate_value

    def exchange(amount)
      rate.exchange amount, outcome_currency
    end

    def reverse_exchange(amount)
      rate.reverse_exchange amount, income_currency
    end

    def currency_pair
      @currency_pair ||= CurrencyPair.new income_currency, outcome_currency
    end

    def income_currency
      ps_from.currency
    end

    def outcome_currency
      ps_to.currency
    end

    def ps_comission
      ps_to.commission
    end

    def in_money
      return 1 if rate_value < 1

      rate_value
    end

    def out_money
      return 1.0 / rate_value if rate_value < 1

      1
    end

    def rate
      RateFromMultiplicator.new(rate_value).freeze
    end

    def rate_money
      Money.from_amount(rate_value, currency_rate.currency_to)
    end

    def base_rate
      RateFromMultiplicator.new(base_rate_value).freeze
    end

    def inverse_direction_rate
      Universe.direction_rates_repository.get_matrix[ps_to_id][ps_from_id]
    end

    def get_profit_result(income_amount)
      res = calculate_profits(
        base_rate: base_rate_value,
        comission: rate_percent,
        ps_interest: ps_comission,
        income_amount: income_amount
      )

      diff = res.finite_rate.to_f.as_percentage_of(rate_value.to_f) - 100

      logger.warn "direction_rate_id=#{id} Calculates finite rate (#{res.finite_rate}) does not equal to current (#{rate_value}). Difference is #{diff}" if diff.abs > 0

      res
    end

    def dump
      as_json(only: %i[id ps_from_id ps_to_id currency_rate_id rate_value base_rate_value rate_percent created_at])
        .merge currency_rate: currency_rate.dump, dump_version: 1
    end

    def exchange_notification
      by_income = ExchangeNotification.find_by(
        income_payment_system_id: income_payment_system_id,
        outcome_payment_system_id: nil
      )

      by_outcome = ExchangeNotification.find_by(
        income_payment_system_id: nil,
        outcome_payment_system_id: outcome_payment_system_id
      )

      return ExchangeNotification.new(
        income_payment_system_id: income_payment_system_id,
        outcome_payment_system_id: outcome_payment_system_id,
        body_ru: [by_income.body_ru, by_outcome.body_ru].join(' <br /><br /> '),
        body_en: [by_income.body_en, by_outcome.body_en].join(' <br /><br /> '),
        body_cs: [by_income.body_cs, by_outcome.body_cs].join(' <br /><br /> ')
      ) if by_income && by_outcome

      ExchangeNotification.find_by(
        income_payment_system_id: income_payment_system_id,
        outcome_payment_system_id: outcome_payment_system_id
      ) || by_income || by_outcome
    end

    def calculate_rate
      self.base_rate_value = currency_rate.rate_value
      raise UnknownExchangeRate, "No exchange_rate for #{ps_from}->#{ps_to}" unless exchange_rate

      self.rate_percent = exchange_rate.final_rate_percents
      self.rate_value = calculate_finite_rate base_rate_value, rate_percent unless rate_percent.nil?
    end
  end
end
