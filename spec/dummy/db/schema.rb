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

ActiveRecord::Schema.define(version: 2018_09_12_130608) do

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
    t.index ["created_at", "ps_from_id", "ps_to_id"], name: "direction_rates_created_at"
    t.index ["currency_rate_id"], name: "fk_rails_d6f1847478"
    t.index ["exchange_rate_id", "id"], name: "index_direction_rates_on_exchange_rate_id_and_id"
    t.index ["ps_from_id", "ps_to_id", "id"], name: "index_direction_rates_on_ps_from_id_and_ps_to_id_and_id"
    t.index ["ps_to_id"], name: "fk_rails_fbaf7f33e1"
  end

end
