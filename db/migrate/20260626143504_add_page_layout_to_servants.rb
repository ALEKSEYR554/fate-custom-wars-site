class AddPageLayoutToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :page_layout, :text
  end
end
