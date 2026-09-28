class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :form, null: false, foreign_key: true
      t.json :answers, null: false
      t.string :unique_digest
      t.datetime :synced_at

      t.timestamps

      t.index [:form_id, :unique_digest], unique: true
      t.index [:form_id, :synced_at]
    end
  end
end
