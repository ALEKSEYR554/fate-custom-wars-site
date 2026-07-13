class CreateCraftEssences < ActiveRecord::Migration[8.1]
  def change
    create_table :craft_essences do |t|
      t.string :game_id
      t.string :name
      t.text :effect

      t.timestamps
    end
  end
end
