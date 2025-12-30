# frozen_string_literal: true

class AddCalculatorTypeToExchangeRates < ActiveRecord::Migration[6.0]
  def change
    add_column :gera_exchange_rates, :calculator_type, :string, default: 'legacy', null: false
    add_index :gera_exchange_rates, :calculator_type
  end
end
