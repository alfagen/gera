# frozen_string_literal: true

class RenameOutcomeAccountFormat < ActiveRecord::Migration[5.2]
  def change
    rename_column :payment_systems, :outcome_account_format, :account_format
    add_column :payment_systems, :validate_income_account, :boolean, default: true
    add_column :payment_systems, :validate_outcome_account, :boolean, default: true
  end
end
