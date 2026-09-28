class AddPurgedAtToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :purged_at, :datetime
    add_index :submissions, :purged_at
  end
end
