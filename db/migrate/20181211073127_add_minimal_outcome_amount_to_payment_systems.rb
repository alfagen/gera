class AddMinimalOutcomeAmountToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    add_column :cms_paymant_system, :minimal_outcome_amount_cents, :integer
  end
end
