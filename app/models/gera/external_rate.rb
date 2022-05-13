# frozen_string_literal: true

# Курсы внешних систем
module Gera
  class ExternalRate < ApplicationRecord
    include CurrencyPairSupport

    belongs_to :source, class_name: 'RateSource'
    belongs_to :snapshot, class_name: 'ExternalRateSnapshot'

    scope :ordered, -> { order :cur_from, :cur_to }

    scope :with_auto_rates, -> { where(auto_rate_enabled: true) }

    before_validation do
      self.source ||= snapshot.try :rate_source
    end

    before_validation :upcase_currencies

    # TODO: validate cur_from, cur_to из списка разрешенных

    delegate :actual_for, to: :snapshot

    def direction_rate
      Universe.direction_rates_repository.find_direction_rate_by_exchange_rate_id id
    end

    def dump
      as_json(only: %i[id cur_from cur_to rate_value source_id created_at])
    end

    def final_rate_percents
      auto_rate_enabled? ? auto_rate_value_by_reserve : comission_percents
    end

    private

    def auto_rate_value_by_reserve
      ((auto_rate_by_reserve_from_boundary + auto_rate_by_reserve_to_boundary) / 2.0).round(2)
    end

    def auto_rate_by_reserve_from_boundary
      min_checkpoint = payment_system_from.auto_rate_settings.find_by(direction: :income)&.checkpoint
      max_checkpoint = payment_system_to.auto_rate_settings.find_by(direction: :outcome)&.checkpoint
      return 0.0 if min_checkpoint.nil? || max_checkpoint.nil?

      ((min_checkpoint.min_boundary + max_checkpoint.min_boundary) / 2.0).round(2)
    end

    def auto_rate_by_reserve_to_boundary
      min_checkpoint = payment_system_from.auto_rate_settings.find_by(direction: :income)&.checkpoint
      max_checkpoint = payment_system_to.auto_rate_settings.find_by(direction: :outcome)&.checkpoint
      return 0.0 if min_checkpoint.nil? || max_checkpoint.nil?

      ((min_checkpoint.max_boundary + max_checkpoint.max_boundary) / 2.0).round(2)
    end

    def upcase_currencies
      self.cur_from = cur_from.to_s.upcase if cur_from.present?
      self.cur_to = cur_to.to_s.upcase if cur_to.present?
    end
  end
end
