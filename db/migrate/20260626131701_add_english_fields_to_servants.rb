class AddEnglishFieldsToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :en_name, :string, default: nil
    add_column :servants, :en_servant_class, :string, default: nil
  end
end
