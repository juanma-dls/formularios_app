module FormsHelper
  FORM_STATUS = {
    "draft"     => ["Borrador", "secondary"],
    "published" => ["Publicado", "success"],
    "closed"    => ["Cerrado", "danger"]
  }.freeze

  def form_status_badge(form)
    label, color = FORM_STATUS[form.status]
    tag.span(label, class: "badge rounded-pill fw-medium bg-#{color}-subtle text-#{color}-emphasis border border-#{color}-subtle")
  end

  def spreadsheet_source_text(form)
    origin = case form.spreadsheet_source
             when Form then "Planilla propia de este formulario"
             when Area then "Heredada del área #{form.area.name}"
             else "Heredada de la organización"
             end
    form.sheet_title.present? ? "#{origin}, pestaña \"#{form.sheet_title}\"" : origin
  end
end