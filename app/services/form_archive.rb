class FormArchive
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def initialize(form)
    @form = form
    @fields = form.fields.select(&:input?)
  end

  def filename
    "#{@form.title.parameterize.presence || 'formulario'}-respuestas.xlsx"
  end

  def to_stream
    package = Axlsx::Package.new
    bold = package.workbook.styles.add_style(b: true)
    sheet = package.workbook.add_worksheet(name: sheet_name)

    sheet.add_row(headers, style: bold)
    types = Array.new(headers.size, :string)
    @form.submissions.where(purged_at: nil).order(:id).find_each do |submission|
      sheet.add_row(row_for(submission), types: types)
    end

    package.to_stream
  end

  private

  def headers
    list = ["ID", "Fecha y hora"] + columns.map { |c| c["label"] }
    list << "Aceptó bases y condiciones" if @form.terms_required?
    list
  end

  def columns
    @columns ||= @fields.flat_map(&:columns)
  end

  def row_for(submission)
    row = [submission.id.to_s, submission.created_at.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")]
    row += columns.map do |column|
      value = FormField.value_for_column(submission.answers, column["key"])
      value.is_a?(Array) ? value.join(", ") : value.to_s
    end
    row << submission.terms_accepted_at&.in_time_zone&.strftime("%Y-%m-%d %H:%M:%S").to_s if @form.terms_required?
    row
  end

  # Excel limita los nombres de hoja a 31 caracteres y no admite algunos símbolos
  def sheet_name
    @form.title.gsub(%r{[\[\]:*?/\\]}, " ").squish.first(31).presence || "Respuestas"
  end
end