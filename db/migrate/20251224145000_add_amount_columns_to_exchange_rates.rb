# frozen_string_literal: true

class AddAmountColumnsToExchangeRates < ActiveRecord::Migration[6.0]
  def change
    return if column_exists?(:gera_exchange_rates, :minamount_cents)

    add_column :gera_exchange_rates, :minamount_cents, :bigint, default: 0, null: false
    add_column :gera_exchange_rates, :minamount_currency, :string, default: 'RUB', null: false
    add_column :gera_exchange_rates, :maxamount_cents, :bigint, default: 0, null: false
    add_column :gera_exchange_rates, :maxamount_currency, :string, default: 'RUB', null: false
  end
end
