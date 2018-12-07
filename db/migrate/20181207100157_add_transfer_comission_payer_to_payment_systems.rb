class AddTransferComissionPayerToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    add_column :cms_paymant_system, :transfer_comission_payer, :integer, null: false, default: 0
  end
end
