class FormSheetSync
  BATCH_SIZE = 500
  FIXED_HEADERS = ["ID", "Fecha y hora"].freeze

  def self.call(form)
    new(form).call
  end

  def initialize(form)
    @form = form
  end

  # Prepara la pestaña, actualiza encabezados y manda lo pendiente.
  # Devuelve true si salió bien; si no, deja el error guardado en el formulario.
  def call
    ensure_tab!
    prune_unused_columns!
    write_header!
    send_pending!
    @form.update!(last_synced_at: Time.current, last_sync_error: nil)
    true
  rescue GoogleSheets::Error => e
    @form.update!(last_sync_error: e.message)
    false
  end

  private

  def prune_unused_columns!
    current = Array(@form.sheet_columns)
    active_keys = @form.fields.select(&:input?).flat_map { |field| field.columns.map { |c| c["key"] } }
    active_keys << Submission::TERMS_KEY if @form.terms_required?

    removable = current.each_index.select do |i|
      key = current[i]["key"]
      !active_keys.include?(key) && !pending_data_for?(key) && column_empty?(FIXED_HEADERS.size + i)
    end
    return if removable.empty?

    GoogleSheets.delete_columns!(@spreadsheet_id, @form.sheet_gid, removable.map { |i| FIXED_HEADERS.size + i })
    @form.update!(sheet_columns: current.reject.with_index { |_, i| removable.include?(i) })
    @columns = nil
  end

  def pending_data_for?(key)
    base = key.split(":", 2).first
    @form.submissions.where(synced_at: nil).any? { |submission| submission.answers[base].present? }
  end

  def column_empty?(index)
    letter = column_letter(index)
    GoogleSheets.column_values(@spreadsheet_id, a1("#{letter}2:#{letter}")).flatten.all?(&:blank?)
  end

  # 0 → A, 25 → Z, 26 → AA
  def column_letter(index)
    name = +""
    number = index + 1
    while number.positive?
      number, remainder = (number - 1).divmod(26)
      name.prepend((65 + remainder).chr)
    end
    name
  end

  def ensure_tab!
    @spreadsheet_id = @form.synced_spreadsheet_id.presence || @form.effective_spreadsheet_id
    raise GoogleSheets::Error, "El formulario no tiene una planilla conectada." if @spreadsheet_id.blank?

    tabs = GoogleSheets.sheet_titles(@spreadsheet_id)
    same_spreadsheet = @form.synced_spreadsheet_id == @spreadsheet_id

    if same_spreadsheet && @form.sheet_gid && tabs[@form.sheet_gid]
      @title = tabs[@form.sheet_gid]
      @form.update!(sheet_title: @title) if @form.sheet_title != @title
    else
      # Pestaña nueva (primera publicación, cambio de planilla o la borraron):
      # se reenvían todas las respuestas para que quede completa.
      @title = unique_title(tabs.values)
      gid = GoogleSheets.add_sheet!(@spreadsheet_id, @title)
      @form.update!(synced_spreadsheet_id: @spreadsheet_id, sheet_gid: gid,
                    sheet_title: @title, sheet_columns: nil)
      @form.submissions.where(purged_at: nil).update_all(synced_at: nil)
    end
  end

  def write_header!
    GoogleSheets.update_values!(@spreadsheet_id, a1("A1"), [FIXED_HEADERS + columns.map { |c| c["label"] }])
    @form.update!(sheet_columns: columns) if @form.sheet_columns != columns
  end

  def send_pending!
    loop do
      batch = @form.submissions.where(synced_at: nil, purged_at: nil).order(:id).limit(BATCH_SIZE).to_a
      break if batch.empty?

      GoogleSheets.append_values!(@spreadsheet_id, a1("A1"), batch.map { |s| row_for(s) })
      Submission.where(id: batch.map(&:id)).update_all(synced_at: Time.current)
      break if batch.size < BATCH_SIZE
    end
  end

  # Columnas en orden: las ya existentes en la planilla y al final los campos nuevos.
  # Los campos borrados conservan su columna con el último nombre que tuvieron.
  def columns
    @columns ||= begin
      cols = Array(@form.sheet_columns).map(&:dup)
      @form.fields.each do |field|
        next if field.section?
        field.columns.each do |column|
          existing = cols.find { |c| c["key"] == column["key"] }
          existing ? existing["label"] = column["label"] : cols << column.dup
        end
      end

      if @form.terms_required? && cols.none? { |c| c["key"] == Submission::TERMS_KEY }
        cols << { "key" => Submission::TERMS_KEY, "label" => "Aceptó bases y condiciones" }
      end

      cols
    end
  end

  def row_for(submission)
    [submission.id, submission.created_at.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")] +
      columns.map do |c|
        if c["key"] == Submission::TERMS_KEY
          submission.terms_accepted_at&.in_time_zone&.strftime("%Y-%m-%d %H:%M:%S").to_s
        else
          cell(FormField.value_for_column(submission.answers, c["key"]))
        end
      end
  end

  # Evita que un valor que empieza con =, +, - o @ se interprete como fórmula
  def cell(value)
    text = value.is_a?(Array) ? value.join(", ") : value.to_s
    text.match?(/\A[=+\-@]/) ? "'#{text}" : text
  end

  def unique_title(existing)
    base = @form.title.gsub(%r{[\[\]:*?/\\]}, " ").squish.first(90).presence || "Formulario"
    title = base
    n = 2
    while existing.include?(title)
      title = "#{base} (#{n})"
      n += 1
    end
    title
  end

  def a1(cell)
    "'#{@title.gsub("'", "''")}'!#{cell}"
  end
end