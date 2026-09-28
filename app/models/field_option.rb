class FieldOption < ApplicationRecord
  IMAGE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  belongs_to :form_field

  has_one_attached :image do |attachable|
    attachable.variant :card, resize_to_limit: [600, 800], preprocessed: true
    attachable.variant :thumb, resize_to_fill: [96, 128], preprocessed: true
  end

  attr_accessor :remove_image

  normalizes :label, with: ->(value) { value.to_s.squish }

  validates :label, presence: true, length: { maximum: 150 }
  validate :image_is_valid

  after_save :purge_image_if_requested

  private

  def image_is_valid
    return unless image.attached?

    errors.add(:image, "debe ser PNG, JPG, WEBP o GIF") unless IMAGE_TYPES.include?(image.blob.content_type)
    errors.add(:image, "no puede pesar más de 5 MB") if image.blob.byte_size > MAX_IMAGE_SIZE
  end

  # Solo se borra si no se eligió una imagen nueva en el mismo guardado
  def purge_image_if_requested
    return unless remove_image == "1" && attachment_changes["image"].nil?
    image.purge_later
  end
end