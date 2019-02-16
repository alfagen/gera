# frozen_string_literal: true

module Gera
  class ExternalRateSnapshot < ApplicationRecord
    belongs_to :rate_source

    has_many :external_rates, foreign_key: :snapshot_id

    scope :ordered, -> { order 'actual_for desc' }
    scope :last_actuals_by_rate_sources, -> { where id: group(:rate_source_id).maximum(:id).values }

    before_save do
      self.actual_for ||= Time.zone.now
    end

    def to_s
      "snapshot[#{id}]:#{rate_source}:#{actual_for}"
    end
  end
end
