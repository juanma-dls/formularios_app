class AddSheetSyncToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :synced_spreadsheet_id, :string
    add_column :forms, :sheet_gid, :integer
    add_column :forms, :sheet_columns, :json
    add_column :forms, :last_synced_at, :datetime
    add_column :forms, :last_sync_error, :text
  end
end
