class AddCaptchaEnabledToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :captcha_enabled, :boolean, default: false, null: false
  end
end
