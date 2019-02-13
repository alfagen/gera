module Gera
  class DirectionRateSnapshot < ApplicationRecord
    has_many :direction_rates, foreign_key: :snapshot_id

    self.table_name = 'direction_rate_snapshots'
  end
end
