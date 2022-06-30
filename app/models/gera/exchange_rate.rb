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
    AUTO_COMISSION_BY_BASE_RATE_UPTIME = 1.hour

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
    before_save :turn_off_auto_comission_by_base_rate_flag_with_delay, if: -> { auto_comission_by_base_rate_changed?(from: false, to: true) }

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

    def final_rate_percents
      if auto_rate?
        auto_comission_by_base_rate? ? comission_by_base_rate + auto_comission_by_reserve : auto_comission_by_reserve
      else
        fixed_comission
      end
    end

    def auto_comission_by_reserve
      ((auto_rate_by_reserve_from + auto_rate_by_reserve_to) / 2.0).round(2)
    end

    def comission_by_base_rate
      ((auto_rate_by_base_from + auto_rate_by_base_to) / 2.0).round(2)
    end

    def auto_rate_by_base_from
      return 0.0 unless auto_rates_by_base_rate_ready?

      calculate_auto_rate_by_base_rate_min_boundary
    end

    def auto_rate_by_base_to
      return 0.0 unless auto_rates_by_base_rate_ready?

      calculate_auto_rate_by_base_rate_max_boundary
    end

    def auto_rate_by_reserve_from
      return 0.0 unless auto_rates_by_reserve_ready?

      calculate_auto_rate_by_reserve_min_boundary
    end

    def auto_rate_by_reserve_to
      return 0.0 unless auto_rates_by_reserve_ready?

      calculate_auto_rate_by_reserve_max_boundary
    end

    def current_base_rate
      @current_base_rate ||= Gera::CurrencyRateHistoryInterval.where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id).last.avg_rate
    end

    def average_base_rate
      @average_base_rate ||= Gera::CurrencyRateHistoryInterval.where('interval_from > ?', DateTime.now.utc - 24.hours).where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id).average(:avg_rate)
    end

    private

    def auto_rates_by_reserve_ready?
      income_reserve_checkpoint.present? && outcome_reserve_checkpoint.present?
    end

    def auto_rates_by_base_rate_ready?
      income_base_rate_checkpoint.present? && outcome_base_rate_checkpoint.present?
    end

    def income_auto_rate_setting
      @income_auto_rate_setting ||= payment_system_from.auto_rate_settings.find_by(direction: 'income')
    end

    def outcome_auto_rate_setting
      @outcome_auto_rate_setting ||= payment_system_from.auto_rate_settings.find_by(direction: 'outcome')
    end

    def income_reserve_checkpoint
      @income_reserve_checkpoint ||= income_auto_rate_setting&.reserve_checkpoint
    end

    def outcome_reserve_checkpoint
      @outcome_reserve_checkpoint ||= outcome_auto_rate_setting&.reserve_checkpoint
    end

    def income_base_rate_checkpoint
      @income_base_rate_checkpoint ||= income_auto_rate_setting&.base_rate_checkpoint(current_base_rate: current_base_rate, average_base_rate: average_base_rate)
    end

    def outcome_base_rate_checkpoint
      @outcome_base_rate_checkpoint ||= outcome_auto_rate_setting&.base_rate_checkpoint(current_base_rate: current_base_rate, average_base_rate: average_base_rate)
    end

    def calculate_auto_rate_by_reserve_min_boundary
      ((income_reserve_checkpoint.min_boundary + outcome_reserve_checkpoint.min_boundary) / 2.0).round(2)
    end

    def calculate_auto_rate_by_reserve_max_boundary
      ((income_reserve_checkpoint.max_boundary + outcome_reserve_checkpoint.max_boundary) / 2.0).round(2)
    end

    def calculate_auto_rate_by_base_rate_min_boundary
      ((income_base_rate_checkpoint.min_boundary + outcome_base_rate_checkpoint.min_boundary) / 2.0).round(2)
    end

    def calculate_auto_rate_by_base_rate_max_boundary
      ((income_base_rate_checkpoint.max_boundary + outcome_base_rate_checkpoint.max_boundary) / 2.0).round(2)
    end

    def update_direction_rates
      DirectionsRatesWorker.perform_async(exchange_rate_id: id)
    end

    def turn_off_auto_comission_by_base_rate_flag_with_delay
      AutoComissionByBaseRateFlagWorker.perform_in(AUTO_COMISSION_BY_BASE_RATE_UPTIME, id)
    end
  end
end
