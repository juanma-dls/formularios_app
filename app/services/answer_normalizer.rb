class AnswerNormalizer
  def self.call(field, raw)
    new(field, raw).call
  end

  def initialize(field, raw)
    @field = field
    @raw = raw
  end

  def call
    value = normalize
    if blank?(value)
      return [nil, @field.required? ? "Esta pregunta es obligatoria." : nil]
    end

    error = validate(value)
    error ? [nil, error] : [value, nil]
  end

  private

  def blank?(value)
    value.nil? || value.empty?
  end

  def normalize
    case @field.field_type
    when "multiple_choice" then Array(@raw).map { |v| v.to_s.strip }.reject(&:empty?).uniq
    when "dni"   then @raw.to_s.gsub(/\D/, "")
    when "phone" then normalize_phone
    when "email" then @raw.to_s.strip.downcase
    else @raw.to_s.strip
    end
  end

  def validate(value)
    case @field.field_type
    when "short_text" then "Máximo 255 caracteres." if value.length > 255
    when "long_text"  then "Máximo 5000 caracteres." if value.length > 5000
    when "number"     then "Ingresá un número válido." unless value.match?(/\A-?\d+([.,]\d+)?\z/)
    when "email"      then "Ingresá un email válido." unless value.match?(URI::MailTo::EMAIL_REGEXP)
    when "phone" then phone_error(value)
    when "dni"        then "El DNI debe tener 7 u 8 números." unless value.match?(/\A\d{7,8}\z/)
    when "date"       then date_error(value)
    when "single_choice", "dropdown", "image_choice"
      "Elegí una opción válida." unless option_labels.include?(value)
    when "multiple_choice"
      "Elegí opciones válidas." unless (value - option_labels).empty?
    end
  end

  def option_labels
    @option_labels ||= @field.options.map(&:label)
  end

  def date_error(value)
    date = Date.iso8601(value)
    "Ingresá una fecha válida." unless date.year.between?(1900, 2100)
  rescue Date::Error
    "Ingresá una fecha válida."
  end

  def normalize_phone
    return @raw.to_s.gsub(/[^\d+]/, "") unless @field.split_area_code?

    parts = @raw.respond_to?(:to_h) ? @raw.to_h.with_indifferent_access : {}
    area = parts[:area].to_s.gsub(/\D/, "").sub(/\A0+/, "")
    number = parts[:number].to_s.gsub(/\D/, "")
    # Si pusieron el 15 del celular, sobran dos dígitos
    number = number.delete_prefix("15") if (area + number).length == 12
    @phone_parts = [area, number]

    area.empty? && number.empty? ? "" : "#{area} #{number}"
  end

  def phone_error(value)
    unless @field.split_area_code?
      return value.match?(/\A\+?\d{8,15}\z/) ? nil : "Ingresá un teléfono con código de área."
    end

    area, number = @phone_parts || ["", ""]
    return "Completá el código de área y el número." if area.empty? || number.empty?
    return nil if area.length.between?(2, 4) && (area + number).length == 10

    "Revisá el código de área y el número: entre los dos tienen que sumar 10 dígitos."
  end
end