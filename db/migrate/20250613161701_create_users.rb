class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.references :family, type: :uuid, foreign_key: true
      t.string :name, limit: 200
      t.string :email, limit: 320
      t.string :password_digest, limit: 200
      t.string :role
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
