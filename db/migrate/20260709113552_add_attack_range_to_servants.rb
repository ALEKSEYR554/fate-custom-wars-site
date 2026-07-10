class AddAttackRangeToServants < ActiveRecord::Migration[8.1]
  def change
    add_column :servants, :attack_range, :integer
  end
end
