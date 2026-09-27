class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :area, optional: true

  enum :role, { viewer: 0, editor: 1, admin: 2 }

  validates :user_id, uniqueness: { scope: [:organization_id, :area_id],
                                    message: "ya es miembro" }
  validate :area_belongs_to_organization

  private

  def area_belongs_to_organization
    return if area.nil? || area.organization_id == organization_id
    errors.add(:area, "no pertenece a esta organización")
  end
end