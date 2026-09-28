class CreateFieldOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :field_options do |t|
      t.references :form_field, null: false, foreign_key: true
      t.string :label, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
