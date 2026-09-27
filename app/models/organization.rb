class Organization < ApplicationRecord
  include SpreadsheetConnectable
  
  has_many :areas, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/ }
  
  def to_param
    slug
  end
end