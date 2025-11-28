# frozen_string_literal: true

# Ensures all foreign keys have ON DELETE CASCADE
# This migration is idempotent - safe to run multiple times
class EnsureCascadeDeleteOnForeignKeys < ActiveRecord::Migration[7.0]
  def up
    # ExchangeRate → PaymentSystem
    update_foreign_key(:gera_exchange_rates, :gera_payment_systems, :income_payment_system_id)
    update_foreign_key(:gera_exchange_rates, :gera_payment_systems, :outcome_payment_system_id)

    # DirectionRate → ExchangeRate
    update_foreign_key(:gera_direction_rates, :gera_exchange_rates, :exchange_rate_id)

    # DirectionRate → PaymentSystem
    update_foreign_key(:gera_direction_rates, :gera_payment_systems, :ps_from_id)
    update_foreign_key(:gera_direction_rates, :gera_payment_systems, :ps_to_id)

    # DirectionRate → CurrencyRate
    update_foreign_key(:gera_direction_rates, :gera_currency_rates, :currency_rate_id)

    # DirectionRateHistoryInterval → PaymentSystem
    update_foreign_key(:gera_direction_rate_history_intervals, :gera_payment_systems, :payment_system_from_id)
    update_foreign_key(:gera_direction_rate_history_intervals, :gera_payment_systems, :payment_system_to_id)
  end

  def down
    # No-op: we don't want to remove cascade on rollback
  end

  private

  def update_foreign_key(from_table, to_table, column)
    # Check if foreign key exists
    fk = foreign_keys(from_table).find { |k| k.column == column.to_s }

    return unless fk

    # Skip if already has cascade
    return if fk.options[:on_delete] == :cascade

    # Remove and recreate with cascade
    remove_foreign_key(from_table, column: column)
    add_foreign_key(from_table, to_table, column: column, on_delete: :cascade)
  end
end
