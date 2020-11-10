# frozen_string_literal: true

# Курсы внешних систем
module Gera
  class ExternalRate < ApplicationRecord
    include CurrencyPairSupport

    belongs_to :source, class_name: 'RateSource'
    belongs_to :snapshot, class_name: 'ExternalRateSnapshot'

    scope :ordered, -> { order :cur_from, :cur_to }

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

    private

    def upcase_currencies
      self.cur_from = cur_from.to_s.upcase if cur_from.present?
      self.cur_to = cur_to.to_s.upcase if cur_to.present?
    end
  end
end
