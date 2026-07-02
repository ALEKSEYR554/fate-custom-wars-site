class CreateDraftSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :draft_sessions do |t|
      t.string :slug
      t.jsonb :data
      t.datetime :expires_at

      t.timestamps
    end
    add_index :draft_sessions, :slug
  end
end
