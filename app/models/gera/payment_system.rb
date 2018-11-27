require 'archivable'

module Gera
  class PaymentSystem < ApplicationRecord
    include ::Archivable
    include Gera::Mathematic

    self.table_name = :cms_paymant_system

    scope :ordered, -> { order :priority }
    scope :enabled,  -> { where 'income_enabled>0 or outcome_enabled>0' }
    scope :disabled,  -> { where income_enabled: false, outcome_enabled: false }

    enum total_computation_method: %i(regular_fee reverse_fee)

    validates :name, presence: true, uniqueness: true
    validates :currency, presence: true

    before_create do
      self.priority = self.class.maximum(:priority).to_i + 1
    end

    after_create :create_exchange_rates

    delegate :iso_code, to: :currency, prefix: true, allow_nil: true

    alias_attribute :commission, :commision
    alias_attribute :archived_at, :deleted_at
    alias_attribute :enable_income, :income_enabled
    alias_attribute :enable_outcome, :outcome_enabled

    def currency
      return unless type_cy
      @currency ||= Money::Currency.find_by_local_id(type_cy) || raise("Не найдена валюта #{type_cy}")
    end

    def currency=(cur)
      cur = Money::Currency.find cur unless cur.is_a? Money::Currency
      self.type_cy = cur.is_a?(Money::Currency) ? cur.local_id : nil
    end

    def to_s
      name
    end

    def total_with_fee(money)
      calculate_total(money: money, fee: transfer_fee)
    end

    def unverified_total_with_fee(money)
      calculate_total(money: money, fee: unverified_transfer_fee)
    end

    private

    def calculate_total(money: , fee:)
      if fee.computation_method == 'regular_fee'
        calculate_total_using_regular_comission(money, fee.amount)
      elsif fee.computation_method == 'reverse_fee'
        calculate_total_using_reverse_comission(money, fee.amount)
      else
        raise NotImplementedError.new("Нет расчета для #{fee.computation_method}")
      end
    end

    def transfer_fee
      OpenStruct.new(
        amount: income_fee,
        computation_method: total_computation_method
      ).freeze
    end

    def unverified_transfer_fee
      OpenStruct.new(
        amount: unverified_income_fee,
        computation_method: total_computation_method
      ).freeze
    end

    def create_exchange_rates
      PaymentSystem.pluck(:id).each do |foreign_id|
        er = ExchangeRate.find_by(payment_system_from_id: id, payment_system_to_id: foreign_id) ||
          ExchangeRate.create!(payment_system_from_id: id, payment_system_to_id: foreign_id, comission: 10)

        if foreign_id != id
          er = ExchangeRate.find_by(payment_system_from_id: foreign_id, payment_system_to_id: id) ||
            ExchangeRate.create!(payment_system_from_id: foreign_id, payment_system_to_id: id, comission: 10)
        end
      end
    end
  end
end
