class AddCraftEssencesToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :craft_essences, :string, array: true, default: []
  end
end
