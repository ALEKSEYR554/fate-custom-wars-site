class CreateServants < ActiveRecord::Migration[8.1]
  def change
    create_table :servants do |t|
      t.string :game_id
      t.integer :rarity
      t.string :region
      t.string :alignment
      t.string :servant_class
      t.string :name
      t.string :endurance_rank
      t.integer :hp
      t.string :strength_rank
      t.integer :damage
      t.string :agility_rank
      t.integer :agility_modifier
      t.string :magic_rank
      t.integer :magic_defense
      t.integer :magic_damage
      t.string :luck_rank
      t.integer :luck_modifier
      t.string :np_rank
      t.text :class_skills
      t.text :personal_skills
      t.text :noble_phantasm
      t.string :image_url
      t.boolean :needs_manual_data

      t.timestamps
    end
  end
end
