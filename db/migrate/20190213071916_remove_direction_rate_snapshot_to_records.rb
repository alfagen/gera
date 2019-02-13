class RemoveDirectionRateSnapshotToRecords < ActiveRecord::Migration[5.2]
  def change
    drop_table :direction_rate_snapshot_to_records
  end
end
