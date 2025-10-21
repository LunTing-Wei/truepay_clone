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

ActiveRecord::Schema[8.0].define(version: 2025_10_20_022629) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "name"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_customers_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "member_type"
    t.index ["email", "member_type"], name: "index_members_on_email_and_member_type", unique: true
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
  end

  create_table "merchants", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "shop_name"
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_merchants_on_member_id"
    t.index ["subdomain"], name: "index_merchants_on_subdomain", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "customer_id", null: false
    t.string "ticket_code"
    t.integer "status", default: 0, null: false
    t.datetime "valid_until"
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "status"], name: "index_order_items_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_order_items_on_customer_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["status"], name: "index_order_items_on_status"
    t.index ["ticket_code"], name: "index_order_items_on_ticket_code", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.integer "amount"
    t.integer "status"
    t.integer "provider"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_id"
    t.index ["customer_id", "created_at"], name: "index_orders_on_customer_id_and_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["transaction_id"], name: "index_orders_on_transaction_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.integer "stock", default: 0, null: false
    t.text "description"
    t.datetime "ticket_expiry"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_deleted", default: false, null: false
    t.index ["is_active"], name: "index_products_on_is_active"
    t.index ["merchant_id"], name: "index_products_on_merchant_id"
  end

  add_foreign_key "customers", "members"
  add_foreign_key "merchants", "members"
  add_foreign_key "order_items", "customers"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "products"
  add_foreign_key "products", "merchants"
end
