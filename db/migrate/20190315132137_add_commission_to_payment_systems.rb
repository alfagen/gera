# frozen_string_literal: true

class AddCommissionToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    add_column :gera_payment_systems, :commission, :float, null: false, default: 0
  end
end
