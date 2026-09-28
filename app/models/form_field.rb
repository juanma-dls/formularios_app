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
    "image_choice"    => "Opción única con imagen",
    "section"         => "Sección (título)"
  }.freeze

  ICONS = {
    "short_text"      => "bi-input-cursor-text",
    "long_text"       => "bi-text-paragraph",
    "number"          => "bi-123",
    "email"           => "bi-envelope",
    "phone"           => "bi-telephone",
    "dni"             => "bi-person-vcard",
    "date"            => "bi-calendar-event",
    "single_choice"   => "bi-ui-radios",
    "dropdown"        => "bi-menu-button-wide",
    "multiple_choice" => "bi-ui-checks",
    "image_choice"    => "bi-images",
    "section"         => "bi-type-h2"
  }.freeze

  CHOICE_TYPES   = %w[single_choice dropdown multiple_choice image_choice].freeze
  UNIQUE_ALLOWED = %w[short_text number email phone dni].freeze
  SINGLE_IN_PRESETS = %w[dni].freeze

  belongs_to :form
  has_many :options, -> { order(:position) }, class_name: "FieldOption",
           dependent: :destroy, inverse_of: :form_field

  accepts_nested_attributes_for :options, allow_destroy: true,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["label"].blank? }

  before_validation :set_defaults, on: :create
  before_validation :normalize_option_positions
  before_validation :clear_input_flags, if: :section?
  before_validation { self.starts_page = false unless section? }

  validates :label, presence: true, length: { maximum: 200 }
  validates :field_type, inclusion: { in: TYPES.keys }
  validates :key, presence: true, uniqueness: { scope: :form_id }
  validate :choice_options_present, if: :choice?
  validate :unique_answer_allowed, if: :unique_answer?
  validate :option_labels_unique, if: :choice?

  after_save :sync_options, if: -> { @options_text && choice? }
  after_commit :refresh_unique_digests, on: %i[create update], if: :saved_change_to_unique_answer?
  after_destroy_commit :refresh_unique_digests, if: :unique_answer?
  after_commit :refresh_sheet_header, if: -> { form.published? }

  def choice?
    CHOICE_TYPES.include?(field_type)
  end

  def icon
    ICONS[field_type]
  end

  def type_name
    TYPES[field_type]
  end

  def section?
    field_type == "section"
  end

  def input?
    !section?
  end

  # Las opciones se editan como texto, una por línea
  def options_text
    @options_text || options.map(&:label).join("\n")
  end

  def options_text=(value)
    @options_text = value.to_s
  end

  def duplicate!
    transaction do
      FormField.where(form_id: form_id).where("position > ?", position).update_all("position = position + 1")
      copy = form.fields.create!(
        field_type: field_type,
        label: "#{label} (copia)",
        help_text: help_text,
        required: required,
        position: position + 1,
        options_text: options.map(&:label).join("\n")
      )

      options.each do |option|
        next unless option.image.attached?
        copy.options.find_by(label: option.label)&.image&.attach(
          io: StringIO.new(option.image.download),
          filename: option.image.filename.to_s,
          content_type: option.image.content_type
        )
      end
      copy
    end
  end

  private

  def clear_input_flags
    self.required = false
    self.unique_answer = false
  end

  def option_labels_unique
    repeated = active_option_labels.group_by(&:downcase).select { |_, labels| labels.size > 1 }.map { |_, labels| labels.first }
    errors.add(:options, "tiene opciones repetidas: #{repeated.to_sentence}") if repeated.any?
  end

  # Opciones vigentes, vengan del texto (bloques y duplicados) o del editor
  def active_option_labels
    return parsed_options if @options_text
    options.reject(&:marked_for_destruction?).map { |o| o.label.to_s.squish }.reject(&:blank?)
  end

  def normalize_option_positions
    return if @options_text
    options.reject(&:marked_for_destruction?)
          .sort_by { |o| o.position.to_i }
          .each.with_index(1) { |option, i| option.position = i }
  end

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