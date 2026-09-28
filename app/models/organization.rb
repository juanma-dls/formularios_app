class Organization < ApplicationRecord
  include SpreadsheetConnectable

  BRAND_COLOR = /\A#\h{6}\z/
  MAX_BRAND_IMAGE = 5.megabytes

  has_one_attached :logo do |attachable|
    attachable.variant :header, resize_to_limit: [240, 96], preprocessed: true
  end
  has_one_attached :banner do |attachable|
    attachable.variant :header, resize_to_limit: [1440, 480], preprocessed: true
  end
  
  has_many :areas, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  attr_accessor :remove_logo, :remove_banner

  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/ }
  validates :brand_color, format: { with: BRAND_COLOR }, allow_blank: true
  validate :brand_images_valid

  after_save :purge_brand_images_if_requested
  
  def to_param
    slug
  end

  private

  def brand_images_valid
    { logo: logo, banner: banner }.each do |name, file|
      next unless file.attached?
      errors.add(name, "debe ser PNG, JPG o WEBP") unless FieldOption::IMAGE_TYPES.include?(file.blob.content_type)
      errors.add(name, "no puede pesar más de 5 MB") if file.blob.byte_size > MAX_BRAND_IMAGE
    end
  end

  def purge_brand_images_if_requested
    logo.purge_later if remove_logo == "1" && attachment_changes["logo"].nil?
    banner.purge_later if remove_banner == "1" && attachment_changes["banner"].nil?
  end
end