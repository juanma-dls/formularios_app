class CreateArchiveDownloads < ActiveRecord::Migration[8.1]
  def change
    create_table :archive_downloads do |t|
      t.references :form, null: false, foreign_key: true
      t.string :remote_ip

      t.timestamps
    end
  end
end
