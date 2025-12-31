class AddEnumFieldsToPaymentSystems < ActiveRecord::Migration[8.0]
  def change
    add_column :gera_payment_systems, :total_computation_method, :integer, default: 0
    add_column :gera_payment_systems, :transfer_comission_payer, :integer, default: 0

    # Add missing columns for ExchangeRate
    add_column :gera_exchange_rates, :minamount_cents, :integer, default: 0
    add_column :gera_exchange_rates, :maxamount_cents, :integer, default: 0
    add_column :gera_exchange_rates, :auto_rate, :boolean, default: false
  end
end
