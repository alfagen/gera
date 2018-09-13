class ChangeOutcomeAccountFormatDefaultsToPaymentSystems < ActiveRecord::Migration[5.2]
  def change
    %i(pay_class priority).each do |column|
      change_column_null :cms_paymant_system, column, true
      change_column_default :cms_paymant_system, column, nil
    end

    change_column_default :cms_paymant_system, :outcome_account_format, 'null'
  end
end
