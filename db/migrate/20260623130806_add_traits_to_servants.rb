class AddTraitsToServants < ActiveRecord::Migration[8.1]
  def change
    # добавляем array: true и значение по умолчанию - пустой массив []
    add_column :servants, :traits, :string, array: true, default: []
  end
end
