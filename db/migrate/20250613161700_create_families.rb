class CreateFamilies < ActiveRecord::Migration[8.0]
  def change
    create_table :families, id: :uuid do |t|
      t.string :name, limit: 200
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
