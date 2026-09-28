class AddStartsPageToFormFields < ActiveRecord::Migration[8.1]
  def change
    add_column :form_fields, :starts_page, :boolean, default: false, null: false
  end
end
