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

ActiveRecord::Schema[8.1].define(version: 2026_06_30_093657) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "servants", force: :cascade do |t|
    t.integer "agility_modifier"
    t.string "agility_rank"
    t.string "alignment"
    t.integer "atlas_id"
    t.text "class_skills"
    t.datetime "created_at", null: false
    t.integer "damage"
    t.string "en_name"
    t.string "en_servant_class"
    t.string "endurance_rank"
    t.string "game_id"
    t.integer "hp"
    t.integer "luck_modifier"
    t.string "luck_rank"
    t.integer "magic_damage"
    t.integer "magic_defense"
    t.string "magic_rank"
    t.string "name"
    t.boolean "needs_manual_data"
    t.text "noble_phantasm"
    t.string "np_rank"
    t.text "page_layout"
    t.text "personal_skills"
    t.integer "rarity"
    t.string "region"
    t.string "servant_class"
    t.string "strength_rank"
    t.string "traits", default: [], array: true
    t.datetime "updated_at", null: false
  end
end
