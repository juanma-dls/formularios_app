class CreateAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :areas do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps

      t.index [:organization_id, :slug], unique: true
    end
  end
end