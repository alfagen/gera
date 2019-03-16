# frozen_string_literal: true

class AddIconUrlToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    add_column :gera_payment_systems, :icon_url, :string
  end
end
