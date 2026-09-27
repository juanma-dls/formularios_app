class Area < ApplicationRecord
  include SpreadsheetConnectable

  belongs_to :organization
  has_many :memberships, dependent: :destroy

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :organization_id },
                   format: { with: /\A[a-z0-9-]+\z/ }

  def to_param
    slug
  end

  def effective_spreadsheet_id
    spreadsheet_id.presence || organization.spreadsheet_id
  end
end