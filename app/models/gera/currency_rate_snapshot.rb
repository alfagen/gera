module GERA
  class CurrencyRateSnapshot < ApplicationRecord
    self.table_name = 'currency_rate_snapshots'

    has_many :rates, class_name: 'GERA::CurrencyRate', foreign_key: :snapshot_id
    belongs_to :currency_rate_mode_snapshot

    def currency_rates
      rates
    end
  end
end
