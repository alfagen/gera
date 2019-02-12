# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_12_083609) do

  create_table "cbr_external_rates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "cross_rate_modes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "currency_rate_mode_id", null: false
    t.string "cur_from", null: false
    t.string "cur_to", null: false
    t.bigint "rate_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_rate_mode_id"], name: "index_cross_rate_modes_on_currency_rate_mode_id"
    t.index ["rate_source_id"], name: "index_cross_rate_modes_on_rate_source_id"
  end

  create_table "currency_rate_history_intervals", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "currency_rate_mode_snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.text "details"
    t.index ["status"], name: "index_currency_rate_mode_snapshots_on_status"
    t.index ["title"], name: "index_currency_rate_mode_snapshots_on_title", unique: true
  end

  create_table "currency_rate_modes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "currency_rate_snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "currency_rate_mode_snapshot_id", null: false
    t.index ["currency_rate_mode_snapshot_id"], name: "fk_rails_456167e2a9"
  end

  create_table "currency_rates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "direction_rate_history_intervals", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.float "min_rate", null: false
    t.float "max_rate", null: false
    t.float "min_comission", null: false
    t.float "max_comission", null: false
    t.timestamp "interval_from", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "interval_to", null: false
    t.integer "payment_system_to_id", null: false
    t.integer "payment_system_from_id", null: false
    t.float "avg_rate", null: false
    t.index ["interval_from", "payment_system_from_id", "payment_system_to_id"], name: "drhi_uniq", unique: true
    t.index ["payment_system_from_id"], name: "fk_rails_70f35124fc"
    t.index ["payment_system_to_id"], name: "fk_rails_5c92dd1b7f"
  end

  create_table "direction_rate_snapshot_to_records", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "direction_rate_id", null: false
    t.bigint "direction_rate_snapshot_id", null: false
    t.index ["direction_rate_id"], name: "drstr_dr_id"
    t.index ["direction_rate_snapshot_id", "direction_rate_id"], name: "drstr_unique_index", unique: true
  end

  create_table "direction_rate_snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "direction_rates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "ps_from_id", null: false
    t.integer "ps_to_id", null: false
    t.bigint "currency_rate_id", null: false
    t.float "rate_value", limit: 53, null: false
    t.float "base_rate_value", limit: 53, null: false
    t.float "rate_percent", null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "exchange_rate_id", null: false, unsigned: true
    t.boolean "is_used", default: false, null: false
    t.bigint "snapshot_id"
    t.index ["created_at", "ps_from_id", "ps_to_id"], name: "direction_rates_created_at"
    t.index ["currency_rate_id"], name: "fk_rails_d6f1847478"
    t.index ["exchange_rate_id", "id"], name: "index_direction_rates_on_exchange_rate_id_and_id"
    t.index ["ps_from_id", "ps_to_id", "id"], name: "index_direction_rates_on_ps_from_id_and_ps_to_id_and_id"
    t.index ["ps_to_id"], name: "fk_rails_fbaf7f33e1"
    t.index ["snapshot_id"], name: "fk_rails_392aafe0ef"
  end

  create_table "exchange_rates", id: :integer, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "id_ps1", null: false
    t.integer "id_ps2", null: false
    t.float "value_ps", null: false
    t.integer "timec", default: 0, null: false
    t.string "position", limit: 10, default: "1-7", null: false
    t.float "cor1", default: 0.0, null: false
    t.float "cor2", default: 8.0, null: false
    t.boolean "on_notif", default: true, null: false
    t.boolean "on_corridor", default: false, null: false
    t.boolean "is_enabled", default: false, null: false
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "in_cur", limit: 3, null: false
    t.string "out_cur", limit: 3, null: false
    t.index ["id_ps1", "id_ps2"], name: "exchange_rate_unique_index", unique: true
    t.index ["id_ps2"], name: "fk_rails_ef77ea3609"
    t.index ["is_enabled"], name: "index_exchange_rates_on_is_enabled"
  end

  create_table "external_rate_snapshots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "rate_source_id", null: false
    t.timestamp "actual_for", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.index ["rate_source_id", "actual_for"], name: "index_external_rate_snapshots_on_rate_source_id_and_actual_for", unique: true
    t.index ["rate_source_id"], name: "index_external_rate_snapshots_on_rate_source_id"
  end

  create_table "external_rates", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.string "cur_from", null: false
    t.string "cur_to", null: false
    t.float "rate_value", limit: 53
    t.bigint "snapshot_id", null: false
    t.timestamp "created_at"
    t.index ["snapshot_id", "cur_from", "cur_to"], name: "index_external_rates_on_snapshot_id_and_cur_from_and_cur_to", unique: true
    t.index ["source_id"], name: "index_external_rates_on_source_id"
  end

  create_table "payment_systems", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 60
    t.string "pay_class", limit: 40
    t.string "cur_sign", limit: 10
    t.string "img"
    t.integer "type_cy", null: false
    t.float "internal_transfer", default: 0.0, null: false
    t.float "commision", default: 0.0, null: false
    t.integer "priority", limit: 1
    t.integer "priority_in", limit: 1, unsigned: true
    t.integer "priority_out", limit: 1, unsigned: true
    t.integer "sort", limit: 1, unsigned: true
    t.integer "id_b"
    t.boolean "is_visible", default: true, null: false
    t.string "letter_cod", default: ""
    t.boolean "show_notice", default: false, null: false, unsigned: true
    t.boolean "auto_set_card", default: false, null: false, unsigned: true
    t.boolean "income_enabled", default: false, null: false
    t.boolean "outcome_enabled", default: false, null: false
    t.boolean "referal_output_enabled", default: false, null: false
    t.timestamp "deleted_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "account_format", default: "null", null: false
    t.string "available_outcome_card_brands"
    t.boolean "require_unique_income", default: false, null: false
    t.integer "minimal_income_amount_cents"
    t.string "maximal_income_amount_cents"
    t.string "bestchange_key"
    t.boolean "manual_confirmation_available", default: false, null: false
    t.integer "system_type", default: 0, null: false
    t.boolean "require_income_card_verification", default: false, null: false
    t.boolean "is_issuing_bank", default: false, null: false
    t.float "income_fee", default: 0.0, null: false
    t.string "faq_link"
    t.string "income_account_type", default: "wallet"
    t.string "direct_payment_url"
    t.boolean "require_wallets_api_key", default: false, null: false
    t.boolean "check_incoming_residue", default: false, null: false
    t.integer "reserves_aggregator_id"
    t.string "cheque_format", default: "none", null: false
    t.bigint "reserves_delta_cents", default: 0, null: false
    t.integer "income_wallets_selection", default: 0, null: false
    t.boolean "require_qiwi_phone", default: false, null: false
    t.string "content_path_slug"
    t.string "payment_service_name"
    t.integer "total_computation_method", default: 0, null: false
    t.integer "transfer_comission_payer", default: 0, null: false
    t.integer "minimal_outcome_amount_cents"
    t.boolean "validate_income_account", default: true
    t.boolean "validate_outcome_account", default: true
    t.boolean "require_verify", default: false, null: false
    t.index ["content_path_slug"], name: "index_payment_systems_on_content_path_slug", unique: true
    t.index ["income_enabled"], name: "index_payment_systems_on_income_enabled"
    t.index ["outcome_enabled"], name: "index_payment_systems_on_outcome_enabled"
    t.index ["reserves_aggregator_id"], name: "fk_rails_8d95b43a82"
  end

  create_table "rate_sources", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  add_foreign_key "cross_rate_modes", "currency_rate_modes"
  add_foreign_key "cross_rate_modes", "rate_sources"
  add_foreign_key "currency_rate_modes", "currency_rate_mode_snapshots"
  add_foreign_key "currency_rate_modes", "rate_sources", column: "cross_rate_source1_id"
  add_foreign_key "currency_rate_modes", "rate_sources", column: "cross_rate_source2_id"
  add_foreign_key "currency_rate_modes", "rate_sources", column: "cross_rate_source3_id"
  add_foreign_key "currency_rate_snapshots", "currency_rate_mode_snapshots"
  add_foreign_key "currency_rates", "currency_rate_snapshots", column: "snapshot_id", on_delete: :cascade
  add_foreign_key "currency_rates", "external_rates", column: "external_rate1_id"
  add_foreign_key "currency_rates", "external_rates", column: "external_rate2_id"
  add_foreign_key "currency_rates", "external_rates", column: "external_rate3_id"
  add_foreign_key "currency_rates", "external_rates", on_delete: :nullify
  add_foreign_key "currency_rates", "rate_sources"
  add_foreign_key "direction_rate_history_intervals", "payment_systems", column: "payment_system_from_id"
  add_foreign_key "direction_rate_history_intervals", "payment_systems", column: "payment_system_to_id"
  add_foreign_key "direction_rate_snapshot_to_records", "direction_rate_snapshots", on_delete: :cascade
  add_foreign_key "direction_rate_snapshot_to_records", "direction_rates"
  add_foreign_key "direction_rates", "currency_rates", on_delete: :cascade
  add_foreign_key "direction_rates", "direction_rate_snapshots", column: "snapshot_id", on_delete: :cascade
  add_foreign_key "direction_rates", "exchange_rates"
  add_foreign_key "direction_rates", "payment_systems", column: "ps_from_id"
  add_foreign_key "direction_rates", "payment_systems", column: "ps_to_id"
  add_foreign_key "exchange_rates", "payment_systems", column: "id_ps1"
  add_foreign_key "exchange_rates", "payment_systems", column: "id_ps2"
  add_foreign_key "external_rates", "external_rate_snapshots", column: "snapshot_id", on_delete: :cascade
  add_foreign_key "external_rates", "rate_sources", column: "source_id"
end
