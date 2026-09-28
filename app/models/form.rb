class Form < ApplicationRecord
  include SpreadsheetConnectable

  TERMS_MAX_SIZE = 10.megabytes
  ARCHIVE_GRACE_DAYS = ENV.fetch("ARCHIVE_GRACE_DAYS", 7).to_i
  MAX_RETENTION_DAYS = ENV.fetch("MAX_RETENTION_DAYS", 90).to_i

  has_one_attached :terms_document
  has_one_attached :archive

  belongs_to :area
  has_many :fields, -> { order(:position) }, class_name: "FormField",
           dependent: :destroy, inverse_of: :form
  has_many :submissions, dependent: :destroy
  has_many :archive_downloads, dependent: :delete_all

  enum :status, { draft: 0, published: 1, closed: 2, paused: 3 }

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

  def pages
    groups = fields.to_a.slice_before { |field| field.section? && field.starts_page? }.to_a
    groups.presence || [[]]
  end

  def question_count
    fields.count(&:input?)
  end

  def page_count
    fields.count { |field| field.section? && field.starts_page? } + 1
  end

  def first_archive_download_at
    archive_downloads.minimum(:created_at)
  end

  # Cuándo se borran el archivo y los datos personales: 7 días después de la
  # primera descarga, o a los 90 días del cierre, lo que ocurra antes
  def purge_scheduled_at
    return unless closed? && closed_at && archive_generated_at && data_purged_at.nil?

    limits = [closed_at + MAX_RETENTION_DAYS.days]
    first = first_archive_download_at
    limits << first + ARCHIVE_GRACE_DAYS.days if first
    limits.min
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