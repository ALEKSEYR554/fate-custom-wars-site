class AddAtlasIdToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :atlas_id, :integer, default: nil
  end
end
