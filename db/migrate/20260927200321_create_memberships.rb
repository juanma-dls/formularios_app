class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :area, null: true, foreign_key: true
      t.integer :role, default: 0, null: false

      t.timestamps
    end
  end
end
