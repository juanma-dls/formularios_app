class AddSplitAreaCodeToFormFields < ActiveRecord::Migration[8.1]
  def change
    add_column :form_fields, :split_area_code, :boolean, default: false, null: false
  end
end
