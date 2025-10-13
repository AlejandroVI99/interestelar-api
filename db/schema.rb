# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_01_150043) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "payments", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "stripe_payment_intent_id", null: false
    t.integer "amount", null: false
    t.string "currency"
    t.integer "status", default: 0
    t.string "item_id", null: false
    t.string "item_name", null: false
    t.jsonb "item_data"
    t.jsonb "metadata"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_at"], name: "index_payments_on_confirmed_at"
    t.index ["created_at"], name: "index_payments_on_created_at"
    t.index ["item_data"], name: "index_payments_on_item_data", using: :gin
    t.index ["item_id"], name: "index_payments_on_item_id"
    t.index ["metadata"], name: "index_payments_on_metadata", using: :gin
    t.index ["status"], name: "index_payments_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end
end
