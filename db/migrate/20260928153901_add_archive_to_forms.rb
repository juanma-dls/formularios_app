class AddArchiveToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :archive_generated_at, :datetime
    add_column :forms, :archive_error, :text
    add_column :forms, :results, :json
    add_column :forms, :data_purged_at, :datetime
  end
end
