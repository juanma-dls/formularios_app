class AddBrandColorToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :brand_color, :string
  end
end
