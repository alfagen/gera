class AddSnapshotIdToDirectionRates < ActiveRecord::Migration[5.2]
  def change
    add_column :direction_rates, :snapshot_id, :bigint
    add_foreign_key :direction_rates, :direction_rate_snapshots, column: :snapshot_id, on_delete: :cascade
  end
end
