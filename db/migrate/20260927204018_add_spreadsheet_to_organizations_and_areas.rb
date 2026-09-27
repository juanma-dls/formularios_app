class AddSpreadsheetToOrganizationsAndAreas < ActiveRecord::Migration[8.1]
  def change
    %i[organizations areas].each do |table|
      add_column table, :spreadsheet_id, :string
      add_column table, :spreadsheet_title, :string
      add_column table, :spreadsheet_connected_at, :datetime
    end
  end
end
