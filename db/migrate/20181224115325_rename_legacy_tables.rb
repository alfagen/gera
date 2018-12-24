class RenameLegacyTables < ActiveRecord::Migration[5.2]
  def change
    rename_table 'cms_paymant_system', 'payment_systems'
    rename_table 'cms_exchange_rate', 'exchange_rates'
  end
end
