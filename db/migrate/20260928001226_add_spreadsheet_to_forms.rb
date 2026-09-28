class AddSpreadsheetToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :spreadsheet_id, :string
    add_column :forms, :spreadsheet_title, :string
    add_column :forms, :spreadsheet_connected_at, :datetime
  end
end
