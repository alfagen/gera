class AddTotalComputationToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    add_column :cms_paymant_system, :total_computation_method, :integer, null: false, default: 0
  end
end
