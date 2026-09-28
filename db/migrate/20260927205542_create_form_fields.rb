class CreateFormFields < ActiveRecord::Migration[8.1]
  def change
    create_table :form_fields do |t|
      t.references :form, null: false, foreign_key: true
      t.string :field_type, null: false
      t.string :label, null: false
      t.string :help_text
      t.boolean :required, default: false, null: false
      t.boolean :unique_answer, default: false, null: false
      t.integer :position, null: false
      t.string :key, null: false

      t.timestamps

      t.index [:form_id, :key], unique: true
    end
  end
end
