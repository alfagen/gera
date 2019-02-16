# frozen_string_literal: true

module Gera
  class CurrencyRateSnapshot < ApplicationRecord
    has_many :rates, class_name: 'Gera::CurrencyRate', foreign_key: :snapshot_id
    belongs_to :currency_rate_mode_snapshot

    def currency_rates
      rates
    end
  end
end
