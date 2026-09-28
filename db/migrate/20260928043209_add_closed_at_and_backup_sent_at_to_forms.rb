class AddClosedAtAndBackupSentAtToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :closed_at, :datetime
    add_column :forms, :backup_sent_at, :datetime
  end
end
