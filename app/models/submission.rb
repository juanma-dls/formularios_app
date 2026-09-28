class Submission < ApplicationRecord
  DUPLICATE_MESSAGE = "Ya se registró una respuesta con este dato.".freeze
  TERMS_KEY = "__terms".freeze

  belongs_to :form

  validate :answers_valid
  validate :not_duplicated

  def self.digest_for(form_id, value)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "#{form_id}:#{value}")
  end

  def self.build_from(form, raw, accept_terms: false)
    new(form: form).tap do |submission|
      submission.assign_raw(raw)
      submission.register_terms(accept_terms)
    end
  end

  def field_errors
    @field_errors ||= {}
  end

  def assign_raw(raw)
    values = {}
    form.fields.each do |field|
      value, error = AnswerNormalizer.call(field, raw[field.key])
      if error
        field_errors[field.key] = error
      elsif !value.nil?
        values[field.key] = value
      end
    end
    self.answers = values

    if (field = unique_field) && values[field.key].present?
      self.unique_digest = Submission.digest_for(form_id, values[field.key])
    end
  end

  # Si dos envíos iguales llegan a la vez, el índice único de la base frena el segundo
  def save(**)
    super
  rescue ActiveRecord::RecordNotUnique
    field_errors[unique_field.key] = DUPLICATE_MESSAGE
    false
  end

  def register_terms(accepted)
    return unless form.terms_required?

    if accepted
      self.terms_accepted_at = Time.current
      self.terms_version = form.terms_document.blob.checksum
    else
      field_errors[TERMS_KEY] = "Para enviar tenés que aceptar las bases y condiciones."
    end
  end

  private

  def unique_field
    form.fields.find(&:unique_answer?)
  end

  def answers_valid
    errors.add(:base, "Hay respuestas inválidas") if field_errors.any?
  end

  def not_duplicated
    return if unique_digest.blank?
    return unless Submission.where(form_id: form_id, unique_digest: unique_digest).exists?

    field_errors[unique_field.key] = DUPLICATE_MESSAGE
    errors.add(:base, "Respuesta duplicada")
  end
end