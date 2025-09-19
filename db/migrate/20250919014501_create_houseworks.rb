class CreateHouseworks < ActiveRecord::Migration[8.0]
  def change
    create_table :houseworks, id: :uuid do |t|
      t.references :family, type: :uuid, null: false, foreign_key: true
      t.string :title, limit: 200, null: false
      t.string :description, limit: 500
      t.string :schedule, limit: 100
      t.references :suggested_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.integer :point, null: false, default: 0
      t.boolean :committed, null: false, default: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :houseworks, :deleted_at
  end
end
