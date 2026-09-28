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

ActiveRecord::Schema[8.1].define(version: 2026_09_28_164320) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "archive_downloads", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.string "remote_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_archive_downloads_on_form_id"
  end

  create_table "areas", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spreadsheet_id"
    t.string "spreadsheet_title"
    t.datetime "spreadsheet_connected_at"
    t.index ["organization_id", "slug"], name: "index_areas_on_organization_id_and_slug", unique: true
  end

  create_table "field_options", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "form_field_id", null: false
    t.string "label", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_field_id"], name: "index_field_options_on_form_field_id"
  end

  create_table "form_fields", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.string "field_type", null: false
    t.string "label", null: false
    t.string "help_text"
    t.boolean "required", default: false, null: false
    t.boolean "unique_answer", default: false, null: false
    t.integer "position", null: false
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "starts_page", default: false, null: false
    t.boolean "split_area_code", default: false, null: false
    t.index ["form_id", "key"], name: "index_form_fields_on_form_id_and_key", unique: true
    t.index ["form_id"], name: "index_form_fields_on_form_id"
  end

  create_table "forms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "public_id", null: false
    t.integer "status", default: 0, null: false
    t.text "success_message"
    t.string "sheet_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spreadsheet_id"
    t.string "spreadsheet_title"
    t.datetime "spreadsheet_connected_at"
    t.string "synced_spreadsheet_id"
    t.integer "sheet_gid"
    t.json "sheet_columns"
    t.datetime "last_synced_at"
    t.text "last_sync_error"
    t.boolean "captcha_enabled", default: false, null: false
    t.boolean "terms_required", default: false, null: false
    t.datetime "closed_at"
    t.datetime "archive_generated_at"
    t.text "archive_error"
    t.json "results"
    t.datetime "data_purged_at"
    t.index ["area_id"], name: "index_forms_on_area_id"
    t.index ["public_id"], name: "index_forms_on_public_id", unique: true
  end

  create_table "memberships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "area_id"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_memberships_on_area_id"
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spreadsheet_id"
    t.string "spreadsheet_title"
    t.datetime "spreadsheet_connected_at"
    t.string "brand_color"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "submissions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.json "answers", null: false
    t.string "unique_digest"
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "terms_accepted_at"
    t.string "terms_version"
    t.datetime "purged_at"
    t.index ["form_id", "synced_at"], name: "index_submissions_on_form_id_and_synced_at"
    t.index ["form_id", "unique_digest"], name: "index_submissions_on_form_id_and_unique_digest", unique: true
    t.index ["form_id"], name: "index_submissions_on_form_id"
    t.index ["purged_at"], name: "index_submissions_on_purged_at"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "archive_downloads", "forms"
  add_foreign_key "areas", "organizations"
  add_foreign_key "field_options", "form_fields"
  add_foreign_key "form_fields", "forms"
  add_foreign_key "forms", "areas"
  add_foreign_key "memberships", "areas"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "submissions", "forms"
end
