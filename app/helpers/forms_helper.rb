module FormsHelper
  FORM_STATUS = {
    "draft"     => ["Borrador", "secondary"],
    "published" => ["Publicado", "success"],
    "closed"    => ["Cerrado", "dark"]
  }.freeze

  def form_status_badge(form)
    label, color = FORM_STATUS[form.status]
    tag.span(label, class: "badge text-bg-#{color} align-middle fs-6")
  end
end