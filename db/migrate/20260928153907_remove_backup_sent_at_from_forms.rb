class RemoveBackupSentAtFromForms < ActiveRecord::Migration[8.1]
  def change
    remove_column :forms, :backup_sent_at, :datetime
  end
end
