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

ActiveRecord::Schema[8.1].define(version: 2026_08_02_054135) do
  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "comment_type", limit: 10, default: "manual", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "inquiry_id", null: false
    t.bigint "staff_id"
    t.index ["inquiry_id"], name: "idx_comments_inquiry_id"
    t.index ["staff_id"], name: "index_comments_on_staff_id"
  end

  create_table "inquiries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "category", limit: 50, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone", limit: 20
    t.string "priority", limit: 10, default: "未設定"
    t.bigint "staff_id"
    t.string "status", limit: 20, default: "未対応", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "idx_inquiries_created_at"
    t.index ["staff_id"], name: "idx_inquiries_staff_id"
    t.index ["status"], name: "idx_inquiries_status"
  end

  create_table "staffs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_staffs_on_email", unique: true
  end

  add_foreign_key "comments", "inquiries"
  add_foreign_key "comments", "staffs"
  add_foreign_key "inquiries", "staffs"
end
