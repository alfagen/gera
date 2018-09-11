module GERA
  class DirectionRateSnapshot < ApplicationRecord
    has_many :direction_rate_snapshot_to_records
    has_many :direction_rates, through: :direction_rate_snapshot_to_records

    self.table_name = 'direction_rate_snapshots'
  end
end
