class AddTermsToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :terms_required, :boolean, default: false, null: false
  end
end
