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

    after_commit :update_direction_rates, if: -> { previous_changes.key?('value') }

    before_create do
      self.in_cur = payment_system_from.currency.to_s
      self.out_cur = payment_system_to.currency.to_s
      self.comission ||= DEFAULT_COMISSION
    end

    validates :commission, presence: true

    delegate :rate, :currency_rate, to: :direction_rate

    alias_attribute :ps_from_id, :income_payment_system_id
    alias_attribute :ps_to_id, :outcome_payment_system_id
    alias_attribute :payment_system_from_id, :income_payment_system_id
    alias_attribute :payment_system_to_id, :outcome_payment_system_id

    alias_attribute :comission, :value
    alias_attribute :commission, :value
    alias_attribute :comission_percents, :value

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
      update! comission: calculate_comission(finite_rate, currency_rate.rate_value)
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

    private

    def update_direction_rates
      DirectionsRatesWorker.perform_async(exchange_rate_id: id)
    end
  end
end
