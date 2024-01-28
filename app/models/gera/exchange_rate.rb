# frozen_string_literal: true

# Комиссия для расчета конечного курса между платежными системами
# TODO: Пеерименовать в Direction
# Комиссии по направлениям платежных систем
# если в парсере операторы изменили курс/комиссию, то эта комиссия
# устанвливается сначала сюда, потом растекается по остальным
#
# * value - само значение комиссии
# * cor1/cor2 - границы коридора
#
# * position - позиция в best которую нужно установить?
# * on_notif - ???
# * on_corridor - в коридоре?
module Gera
  class ExchangeRate < ApplicationRecord
    include Authority::Abilities

    DEFAULT_COMISSION = 50
    MIN_COMISSION = -9.9

    include Mathematic
    include DirectionSupport

    belongs_to :payment_system_from, foreign_key: :income_payment_system_id, class_name: 'Gera::PaymentSystem'
    belongs_to :payment_system_to, foreign_key: :outcome_payment_system_id, class_name: 'Gera::PaymentSystem'

    scope :ordered, -> { order :id }
    scope :enabled, -> { where is_enabled: true }

    scope :with_payment_systems, lambda {
      includes(:payment_system_from, :payment_system_to)
        .joins(:payment_system_from, :payment_system_to)
    }

    scope :available, lambda {
      with_payment_systems
        .enabled
        .where("#{PaymentSystem.table_name}.income_enabled and payment_system_tos_gera_exchange_rates.outcome_enabled")
        .where("#{table_name}.income_payment_system_id <> #{table_name}.outcome_payment_system_id")
    }
    scope :with_auto_rates, -> { where(auto_rate: true) }

    after_commit :update_direction_rates, if: -> { previous_changes.key?('value') }
    before_save :turn_off_auto_comission_by_base, if: :auto_comission_by_base_rate_turned_on?

    before_create do
      self.in_cur = payment_system_from.currency.to_s
      self.out_cur = payment_system_to.currency.to_s
      self.comission ||= DEFAULT_COMISSION
    end

    validates :commission, presence: true
    validates :commission, numericality: { greater_than_or_equal_to: MIN_COMISSION }

    delegate :rate, :currency_rate, to: :direction_rate

    delegate  :auto_comission_by_reserve, :comission_by_base_rate, :auto_rate_by_base_from,
              :auto_rate_by_base_to, :auto_rate_by_reserve_from, :auto_rate_by_reserve_to,
              :current_base_rate, :average_base_rate, :auto_comission_from,
              :auto_comission_to, :bestchange_delta, to: :rate_comission_calculator

    alias_attribute :ps_from_id, :income_payment_system_id
    alias_attribute :ps_to_id, :outcome_payment_system_id
    alias_attribute :payment_system_from_id, :income_payment_system_id
    alias_attribute :payment_system_to_id, :outcome_payment_system_id

    alias_attribute :comission, :value
    alias_attribute :commission, :value
    alias_attribute :comission_percents, :value
    alias_attribute :fixed_comission, :value

    alias_attribute :income_payment_system, :payment_system_from
    alias_attribute :outcome_payment_system, :payment_system_to

    def self.list_rates
      order('id asc').each_with_object({}) do |er, h|
        h[er.income_payment_system_id] ||= {}
        h[er.income_payment_system_id][er.outcome_payment_system_id] = h.value
      end
    end

    def available?
      is_enabled?
    end

    def update_finite_rate!(finite_rate)
      logger = Logger.new("#{Rails.root}/log/call_exchange_rate_updater_worker.log")
      logger.info("Calls perform_async from update_finite_rate Gera::ExchangeRate")

      ExchangeRateUpdaterWorker.perform_async(id, { comission: calculate_comission(finite_rate, currency_rate.rate_value) })
    end

    def custom_inspect
      {
        value: value,
        exchange_rate_id: id,
        payment_system_to: payment_system_to.to_s,
        payment_system_from: payment_system_from.to_s,
        out_currency: out_currency.to_s,
        in_currency: in_currency.to_s
      }.to_s
    end

    def currency_pair
      @currency_pair ||= CurrencyPair.new in_currency, out_currency
    end

    def out_currency
      Money::Currency.find out_cur
    end

    def currency_to
      out_currency
    end

    def currency_from
      in_currency
    end

    def in_currency
      Money::Currency.find in_cur
    end

    def finite_rate
      direction_rate.rate
    end

    def to_s
      [in_currency, out_currency].join '/'
    end

    def direction_rate
      Universe.direction_rates_repository.find_direction_rate_by_exchange_rate_id id
    end

    def final_rate_percents
      auto_rate? ? rate_comission_calculator.auto_comission : rate_comission_calculator.fixed_comission
    end

    def update_direction_rates
      DirectionsRatesWorker.perform_async(exchange_rate_id: id)
    end

    def turn_off_auto_comission_by_base
      AutoComissionByBaseRateFlagWorker.perform_async(id)
    end

    def auto_comission_by_base_rate_turned_on?
      auto_comission_by_base_rate_changed?(from: false, to: true)
    end

    def rate_comission_calculator
      @rate_comission_calculator ||= RateComissionCalculator.new(exchange_rate: self, external_rates: external_rates)
    end

    def external_rates
      @external_rates ||= BestChange::Service.new(exchange_rate: self).rows
    end
  end
end
