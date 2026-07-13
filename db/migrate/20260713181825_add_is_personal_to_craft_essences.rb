class AddIsPersonalToCraftEssences < ActiveRecord::Migration[8.1]
  def change
    add_column :craft_essences, :is_personal, :boolean, default: false
  end
end
