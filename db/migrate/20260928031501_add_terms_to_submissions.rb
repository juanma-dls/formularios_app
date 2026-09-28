class AddTermsToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :terms_accepted_at, :datetime
    add_column :submissions, :terms_version, :string
  end
end
