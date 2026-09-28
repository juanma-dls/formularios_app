class CreateForms < ActiveRecord::Migration[8.1]
  def change
    create_table :forms do |t|
      t.references :area, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :public_id, null: false
      t.integer :status, default: 0, null: false
      t.text :success_message
      t.string :sheet_title

      t.timestamps
    end
    add_index :forms, :public_id, unique: true
  end
end
