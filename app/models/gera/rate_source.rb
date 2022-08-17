# frozen_string_literal: true

module Gera
  class RateSource < ApplicationRecord
    include Authority::Abilities
    extend CurrencyPairGenerator
    RateNotFound = Class.new StandardError

    has_many :snapshots, class_name: 'ExternalRateSnapshot'
    has_many :external_rates, foreign_key: :source_id

    belongs_to :actual_snapshot, class_name: 'ExternalRateSnapshot', optional: true

    scope :ordered, -> { order :priority }
    scope :enabled, -> { where is_enabled: true }

    scope :enabled_for_cross_rates, -> { enabled }

    validates :key, presence: true, uniqueness: true
    validate :candidate_snapshot_rates_count_valid?, on: :update, if: :actual_snapshot_id_changed?

    before_create do
      self.priority ||= RateSource.maximum(:priority).to_i + 1
    end

    before_validation do
      self.title ||= self.class.name.underscore
      self.key ||= self.class.name.underscore
    end

    delegate :supported_currencies, :available_pairs, to: :class

    def self.supported_currencies
      raise 'not implemented'
    end

    def self.available_pairs
      generate_pairs_from_currencies supported_currencies
    end

    def self.get!
      where(type: name).take!
    end

    def find_rate_by_currency_pair!(pair)
      find_rate_by_currency_pair(pair) || raise(RateNotFound, pair)
    end

    def find_rate_by_currency_pair(pair)
      actual_rates.find_by_currency_pair pair
    end

    def to_s
      name
    end

    def actual_rates
      external_rates.where(snapshot_id: actual_snapshot_id)
    end

    def to_s
      title
    end

    def is_currency_supported?(cur)
      cur = Money::Currency.find cur unless cur.is_a? Money::Currency
      supported_currencies.include? cur
    end

    private

    def validate_currency!(*curs)
      curs.each do |cur|
        raise "Источник #{self} не поддерживает валюту #{cur}" unless is_currency_supported? cur
      end
    end

    def candidate_snapshot_rates_count_valid?
      actual_snapshot, candidate_snapshot = snapshots.find(actual_snapshot_id_change)
      # TODO: нужно сравнивать с фактическим к-вом пар, который мы получили в воркере,
      # чтобы при добавлении новых валют в этом месте не возникали проблемы 
      return true if actual_snapshot.external_rates.count == candidate_snapshot.external_rates.count

      errors.add :actual_snapshot_id, 'Некорректое к-во курсов'
      candidate_snapshot.destroy
      false
    end
  end
end
