class AddSortIdToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :sort_id, :integer
  end
end
