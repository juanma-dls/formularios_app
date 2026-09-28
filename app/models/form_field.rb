class FormField < ApplicationRecord
  TYPES = {
    "short_text"      => "Texto corto",
    "long_text"       => "Texto largo",
    "number"          => "Número",
    "email"           => "Email",
    "phone"           => "Teléfono",
    "dni"             => "DNI",
    "date"            => "Fecha",
    "single_choice"   => "Opción única",
    "dropdown"        => "Lista desplegable",
    "multiple_choice" => "Casillas (varias opciones)",
    "image_choice"    => "Opción única con imagen"
  }.freeze

  CHOICE_TYPES   = %w[single_choice dropdown multiple_choice image_choice].freeze
  UNIQUE_ALLOWED = %w[short_text number email phone dni].freeze

  belongs_to :form
  has_many :options, -> { order(:position) }, class_name: "FieldOption",
           dependent: :destroy, inverse_of: :form_field

  before_validation :set_defaults, on: :create

  validates :label, presence: true, length: { maximum: 200 }
  validates :field_type, inclusion: { in: TYPES.keys }
  validates :key, presence: true, uniqueness: { scope: :form_id }
  validate :choice_options_present, if: :choice?
  validate :unique_answer_allowed, if: :unique_answer?

  after_save :sync_options, if: -> { @options_text && choice? }
  after_commit :refresh_unique_digests, on: %i[create update], if: :saved_change_to_unique_answer?
  after_destroy_commit :refresh_unique_digests, if: :unique_answer?
  after_commit :refresh_sheet_header, if: -> { form.published? }

  def choice?
    CHOICE_TYPES.include?(field_type)
  end

  def type_name
    TYPES[field_type]
  end

  # Las opciones se editan como texto, una por línea
  def options_text
    @options_text || options.map(&:label).join("\n")
  end

  def options_text=(value)
    @options_text = value.to_s
  end

  def move!(direction)
    siblings = FormField.where(form_id: form_id).order(:position)
    sibling = direction == :up ? siblings.where("position < ?", position).last
                               : siblings.where("position > ?", position).first
    return unless sibling

    transaction do
      mine, theirs = position, sibling.position
      update_columns(position: theirs)
      sibling.update_columns(position: mine)
    end
  end

  private

  def refresh_sheet_header
    SyncFormJob.perform_later(form_id)
  end

  def parsed_options
    options_text.lines.map(&:strip).reject(&:blank?).uniq
  end

  def set_defaults
    self.key ||= SecureRandom.hex(4)
    self.position ||= (FormField.where(form_id: form_id).maximum(:position) || 0) + 1
  end

  def choice_options_present
    errors.add(:options_text, "debe tener al menos 2 opciones") if parsed_options.size < 2
  end

  def unique_answer_allowed
    unless UNIQUE_ALLOWED.include?(field_type)
      errors.add(:unique_answer, "no está disponible para este tipo de campo")
      return
    end
    others = FormField.where(form_id: form_id, unique_answer: true).where.not(id: id)
    errors.add(:unique_answer, "ya está activado en otro campo de este formulario") if others.exists?
  end

  def sync_options
    labels = parsed_options
    current = options.to_a.index_by(&:label)
    options.where.not(label: labels).destroy_all
    labels.each_with_index do |label, i|
      option = current[label] || options.build(label: label)
      option.position = i + 1
      option.save!
    end
    options.reset
    @options_text = nil
  end

  def refresh_unique_digests
    RefreshUniqueDigestsJob.perform_later(form_id)
  end
end