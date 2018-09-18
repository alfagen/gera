require 'archivable'

module Gera
  class PaymentSystem < ApplicationRecord
    include ::Archivable

    self.table_name = :cms_paymant_system

    scope :ordered, -> { order :priority }
    scope :enabled,  -> { where 'income_enabled>0 or outcome_enabled>0' }
    scope :disabled,  -> { where income_enabled: false, outcome_enabled: false }

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

    # TODO: надо пособирать такие условия и может для каждой платежки сделать json с настройками
    def income_fee_percents
      income_fee.percents
    end

    private

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
