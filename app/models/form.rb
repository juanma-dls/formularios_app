class Form < ApplicationRecord
  include SpreadsheetConnectable

  TERMS_MAX_SIZE = 10.megabytes

  has_one_attached :terms_document

  belongs_to :area
  has_many :fields, -> { order(:position) }, class_name: "FormField",
           dependent: :destroy, inverse_of: :form
  has_many :submissions, dependent: :destroy

  enum :status, { draft: 0, published: 1, closed: 2 }

  delegate :organization, to: :area

  before_validation :generate_public_id, on: :create

  validates :title, presence: true, length: { maximum: 150 }
  validates :public_id, presence: true, uniqueness: true
  validate :captcha_configured, if: :captcha_enabled?
  validate :terms_document_valid
  validate :terms_locked_while_published, if: :published?

  def to_param
    public_id
  end

  def effective_spreadsheet_id
    spreadsheet_id.presence || area.effective_spreadsheet_id
  end

  def spreadsheet_source
    return self if spreadsheet_connected?
    return area if area.spreadsheet_connected?
    organization if organization.spreadsheet_connected?
  end

  private

  def captcha_configured
    return if TurnstileVerifier.configured?
    errors.add(:captcha_enabled, "no se puede activar porque faltan las claves de Turnstile en el servidor")
  end

  def generate_public_id
    self.public_id ||= loop do
      token = SecureRandom.alphanumeric(10).downcase
      break token unless Form.exists?(public_id: token)
    end
  end

  def terms_document_valid
    if terms_required? && !terms_document.attached?
      errors.add(:terms_document, "es obligatorio si pedís aceptar bases y condiciones")
    end
    return unless terms_document.attached?

    errors.add(:terms_document, "debe ser un archivo PDF") unless terms_document.blob.content_type == "application/pdf"
    errors.add(:terms_document, "no puede pesar más de 10 MB") if terms_document.blob.byte_size > TERMS_MAX_SIZE
  end

  def terms_locked_while_published
    return unless attachment_changes["terms_document"] || will_save_change_to_terms_required?
    errors.add(:base, "Para cambiar las bases y condiciones, primero cerrá el formulario.")
  end
end