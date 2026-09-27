class Area < ApplicationRecord
  belongs_to :organization
  has_many :memberships, dependent: :destroy

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :organization_id },
                   format: { with: /\A[a-z0-9-]+\z/ }

  def to_param
    slug
  end
end