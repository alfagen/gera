class Setup < ActiveRecord::Migration[5.2]
  MYSQL_OPTIONS = "ENGINE=InnoDB DEFAULT CHARSET=utf8"

  def change
    if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) &&
        connection.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      table_options = MYSQL_OPTIONS
      execute "SET SQL_MODE='ALLOW_INVALID_DATES';"
    end

    create_table "gera_external_rate_snapshots", options: table_options, force: :cascade do |t|
      t.bigint "rate_source_id", null: false
      t.timestamp "actual_for", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.datetime "created_at", null: false
      t.index ["rate_source_id", "actual_for"], name: "index_external_rate_snapshots_on_rate_source_id_and_actual_for", unique: true
      t.index ["rate_source_id"], name: "index_external_rate_snapshots_on_rate_source_id"
    end

    create_table "gera_external_rates", options: table_options, force: :cascade do |t|
      t.bigint "source_id", null: false
      t.string "cur_from", null: false
      t.string "cur_to", null: false
      t.float "rate_value", limit: 53
      t.bigint "snapshot_id", null: false
      t.timestamp "created_at"
      t.index ["snapshot_id", "cur_from", "cur_to"], name: "index_external_rates_on_snapshot_id_and_cur_from_and_cur_to", unique: true
      t.index ["source_id"], name: "index_external_rates_on_source_id"
    end

    create_table "gera_rate_sources", options: table_options, force: :cascade do |t|
      t.string "title", null: false
      t.string "type", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "key", null: false
      t.bigint "actual_snapshot_id"
      t.integer "priority", default: 0, null: false
      t.boolean "is_enabled", default: true, null: false
      t.index ["actual_snapshot_id"], name: "fk_rails_0b6cf3ddaa"
      t.index ["key"], name: "index_rate_sources_on_key", unique: true
      t.index ["title"], name: "index_rate_sources_on_title", unique: true
    end

    create_table "gera_cross_rate_modes", options: table_options, force: :cascade do |t|
      t.bigint "currency_rate_mode_id", null: false
      t.string "cur_from", null: false
      t.string "cur_to", null: false
      t.bigint "rate_source_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["currency_rate_mode_id"], name: "index_cross_rate_modes_on_currency_rate_mode_id"
      t.index ["rate_source_id"], name: "index_cross_rate_modes_on_rate_source_id"
    end

    create_table "gera_direction_rate_history_intervals", options: table_options, force: :cascade do |t|
      t.float "min_rate", null: false
      t.float "max_rate", null: false
      t.float "min_comission", null: false
      t.float "max_comission", null: false
      t.timestamp "interval_from", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp "interval_to", null: false
      t.bigint "payment_system_to_id", null: false
      t.bigint "payment_system_from_id", null: false
      t.float "avg_rate", null: false
      t.index ["interval_from", "payment_system_from_id", "payment_system_to_id"], name: "drhi_uniq", unique: true
      t.index ["payment_system_from_id"], name: "fk_rails_70f35124fc"
      t.index ["payment_system_to_id"], name: "fk_rails_5c92dd1b7f"
    end

    create_table "gera_currency_rate_history_intervals", options: table_options, force: :cascade do |t|
      t.integer "cur_from_id", limit: 1, null: false
      t.integer "cur_to_id", limit: 1, null: false
      t.float "min_rate", null: false
      t.float "avg_rate", null: false
      t.float "max_rate", null: false
      t.timestamp "interval_from", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp "interval_to", null: false
      t.index ["cur_from_id", "cur_to_id", "interval_from"], name: "crhi_unique_index", unique: true
      t.index ["interval_from"], name: "index_currency_rate_history_intervals_on_interval_from"
    end

    create_table "gera_currency_rate_mode_snapshots", options: table_options, force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "status", default: 0, null: false
      t.string "title"
      t.text "details"
      t.index ["status"], name: "index_currency_rate_mode_snapshots_on_status"
      t.index ["title"], name: "index_currency_rate_mode_snapshots_on_title", unique: true
    end

    create_table "gera_currency_rate_modes", options: table_options, force: :cascade do |t|
      t.string "cur_from", null: false
      t.string "cur_to", null: false
      t.integer "mode", default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "currency_rate_mode_snapshot_id", null: false
      t.string "cross_currency1"
      t.bigint "cross_rate_source1_id"
      t.string "cross_currency2"
      t.string "cross_currency3"
      t.bigint "cross_rate_source2_id"
      t.bigint "cross_rate_source3_id"
      t.index ["cross_rate_source1_id"], name: "index_currency_rate_modes_on_cross_rate_source1_id"
      t.index ["cross_rate_source2_id"], name: "index_currency_rate_modes_on_cross_rate_source2_id"
      t.index ["cross_rate_source3_id"], name: "index_currency_rate_modes_on_cross_rate_source3_id"
      t.index ["currency_rate_mode_snapshot_id", "cur_from", "cur_to"], name: "crm_id_pair", unique: true
    end

    create_table "gera_currency_rate_snapshots", options: table_options, force: :cascade do |t|
      t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.bigint "currency_rate_mode_snapshot_id", null: false
      t.index ["currency_rate_mode_snapshot_id"], name: "fk_rails_456167e2a9"
    end

    create_table "gera_currency_rates", options: table_options, force: :cascade do |t|
      t.string "cur_from", null: false
      t.string "cur_to", null: false
      t.float "rate_value", limit: 53, null: false
      t.bigint "snapshot_id", null: false
      t.json "metadata", null: false
      t.timestamp "created_at"
      t.bigint "external_rate_id"
      t.integer "mode", null: false
      t.bigint "rate_source_id"
      t.bigint "external_rate1_id"
      t.bigint "external_rate2_id"
      t.bigint "external_rate3_id"
      t.index ["created_at", "cur_from", "cur_to"], name: "currency_rates_created_at"
      t.index ["external_rate1_id"], name: "index_currency_rates_on_external_rate1_id"
      t.index ["external_rate2_id"], name: "index_currency_rates_on_external_rate2_id"
      t.index ["external_rate3_id"], name: "index_currency_rates_on_external_rate3_id"
      t.index ["external_rate_id"], name: "fk_rails_905ddd038e"
      t.index ["rate_source_id"], name: "fk_rails_2397c780d5"
      t.index ["snapshot_id", "cur_from", "cur_to"], name: "index_current_exchange_rates_uniq", unique: true
    end

    create_table "gera_direction_rate_snapshots", options: table_options, force: :cascade do |t|
      t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    create_table "gera_direction_rates", options: table_options, force: :cascade do |t|
      t.bigint "ps_from_id", null: false
      t.bigint "ps_to_id", null: false
      t.bigint "currency_rate_id", null: false
      t.float "rate_value", limit: 53, null: false
      t.float "base_rate_value", limit: 53, null: false
      t.float "rate_percent", null: false
      t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.bigint "exchange_rate_id", null: false
      t.boolean "is_used", default: false, null: false
      t.bigint "snapshot_id"
      t.index ["created_at", "ps_from_id", "ps_to_id"], name: "direction_rates_created_at"
      t.index ["currency_rate_id"], name: "fk_rails_d6f1847478"
      t.index ["exchange_rate_id", "id"], name: "index_direction_rates_on_exchange_rate_id_and_id"
      t.index ["ps_from_id", "ps_to_id", "id"], name: "index_direction_rates_on_ps_from_id_and_ps_to_id_and_id"
      t.index ["ps_to_id"], name: "fk_rails_fbaf7f33e1"
      t.index ["snapshot_id"], name: "fk_rails_392aafe0ef"
    end

    create_table "gera_cbr_external_rates", options: table_options, force: :cascade do |t|
      t.date "date", null: false
      t.string "cur_from", null: false
      t.string "cur_to", null: false
      t.float "rate", null: false
      t.float "original_rate", null: false
      t.integer "nominal", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["cur_from", "cur_to", "date"], name: "index_cbr_external_rates_on_cur_from_and_cur_to_and_date", unique: true
    end

    create_table "gera_exchange_rates", options: table_options, force: :cascade do |t|
      t.bigint "income_payment_system_id", null: false
      t.string 'in_cur', limit: 4, null: false
      t.string 'out_cur', limit: 4, null: false
      t.bigint "outcome_payment_system_id", null: false
      t.float "value", null: false
      t.boolean "is_enabled", default: false, null: false
      t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.index ["income_payment_system_id", "outcome_payment_system_id"], name: "exchange_rate_unique_index", unique: true
      t.index ["outcome_payment_system_id"], name: "fk_rails_ef77ea3609"
      t.index ["is_enabled"], name: "index_exchange_rates_on_is_enabled"
    end

    create_table "gera_payment_systems", options: table_options, force: :cascade do |t|
      t.string "name", limit: 60
      t.integer "priority", limit: 1
      t.string "img"
      t.integer "type_cy", null: false
      t.boolean "income_enabled", default: false, null: false
      t.boolean "outcome_enabled", default: false, null: false
      t.timestamp "deleted_at"
      t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.index ["income_enabled"], name: "index_payment_systems_on_income_enabled"
      t.index ["outcome_enabled"], name: "index_payment_systems_on_outcome_enabled"
    end

    add_foreign_key "gera_exchange_rates", "gera_payment_systems", column: "income_payment_system_id", on_delete: :cascade
    add_foreign_key "gera_exchange_rates", "gera_payment_systems", column: "outcome_payment_system_id", on_delete: :cascade
    add_foreign_key "gera_cross_rate_modes", "gera_currency_rate_modes", column: :currency_rate_mode_id, on_delete: :cascade
    add_foreign_key "gera_cross_rate_modes", "gera_rate_sources", column: :rate_source_id, on_delete: :cascade
    add_foreign_key "gera_currency_rate_modes", "gera_currency_rate_mode_snapshots", column: :currency_rate_mode_snapshot_id, on_delete: :cascade
    add_foreign_key "gera_currency_rate_modes", "gera_rate_sources", column: "cross_rate_source1_id", on_delete: :cascade
    add_foreign_key "gera_currency_rate_modes", "gera_rate_sources", column: "cross_rate_source2_id", on_delete: :cascade
    add_foreign_key "gera_currency_rate_modes", "gera_rate_sources", column: "cross_rate_source3_id", on_delete: :cascade
    add_foreign_key "gera_currency_rate_snapshots", "gera_currency_rate_mode_snapshots", column: :currency_rate_mode_snapshot_id, on_delete: :cascade
    add_foreign_key "gera_currency_rates", "gera_currency_rate_snapshots", column: "snapshot_id", on_delete: :cascade
    add_foreign_key "gera_currency_rates", "gera_external_rates", column: "external_rate1_id", on_delete: :cascade
    add_foreign_key "gera_currency_rates", "gera_external_rates", column: "external_rate2_id", on_delete: :cascade
    add_foreign_key "gera_currency_rates", "gera_external_rates", column: "external_rate3_id", on_delete: :cascade
    add_foreign_key "gera_currency_rates", "gera_external_rates", column: :external_rate_id, on_delete: :nullify
    add_foreign_key "gera_currency_rates", "gera_rate_sources", column: :rate_source_id, on_delete: :cascade
    add_foreign_key "gera_direction_rates", "gera_exchange_rates", column: "exchange_rate_id", on_delete: :cascade
    add_foreign_key "gera_direction_rates", "gera_payment_systems", column: "ps_from_id", on_delete: :cascade
    add_foreign_key "gera_direction_rates", "gera_payment_systems", column: "ps_to_id", on_delete: :cascade
    add_foreign_key "gera_direction_rates", "gera_currency_rates", column: :currency_rate_id, on_delete: :cascade
    add_foreign_key "gera_external_rates", "gera_external_rate_snapshots", column: "snapshot_id", on_delete: :cascade
    add_foreign_key "gera_external_rates", "gera_rate_sources", column: "source_id", on_delete: :cascade
    add_foreign_key "gera_direction_rate_history_intervals", "gera_payment_systems", column: "payment_system_from_id", on_delete: :cascade
    add_foreign_key "gera_direction_rate_history_intervals", "gera_payment_systems", column: "payment_system_to_id", on_delete: :cascade
  end
end
