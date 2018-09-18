module Gera
  class DirectionRateSnapshotToRecord < ApplicationRecord
    belongs_to :direction_rate_snapshot
    belongs_to :direction_rate

    self.table_name = 'direction_rate_snapshot_to_records'
  end
end
