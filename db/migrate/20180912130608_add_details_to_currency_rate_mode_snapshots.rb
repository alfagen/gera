class AddDetailsToCurrencyRateModeSnapshots < ActiveRecord::Migration[5.2]
  def change
    add_column :currency_rate_mode_snapshots, :details, :text
  end
end
