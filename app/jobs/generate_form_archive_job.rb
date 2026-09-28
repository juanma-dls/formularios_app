class GenerateFormArchiveJob < ApplicationJob
  def perform(form_id)
    form = Form.find_by(id: form_id)
    return unless form&.closed? && form.data_purged_at.nil?

    archive = FormArchive.new(form)
    form.archive.attach(io: archive.to_stream, filename: archive.filename, content_type: FormArchive::CONTENT_TYPE)
    form.update!(archive_generated_at: Time.current, archive_error: nil, results: FormResults.new(form).call)
  rescue StandardError => e
    form&.update_column(:archive_error, "No se pudo generar el archivo: #{e.message.truncate(300)}")
    raise
  end
end