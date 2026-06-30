class RemoveImageUrlFromServants < ActiveRecord::Migration[8.1]
  def change
    remove_column :servants, :image_url, :string
  end
end
