class FormFieldsController < ApplicationController
  EDITABLE = %i[label help_text required unique_answer starts_page].freeze

  before_action :set_form
  before_action :set_field, only: %i[edit update destroy duplicate]

  def create
    @field = @form.fields.new(params.expect(form_field: [:field_type, *EDITABLE]))
    @field.label = default_label(@field) if @field.label.blank?
    @field.options_text = "Opción 1\nOpción 2" if @field.choice? && @field.options_text.blank?

    if @field.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("fields_empty"),
            turbo_stream.append("fields", partial: "form_fields/editing")
          ]
        end
        format.html { redirect_to @form }
      end
    else
      redirect_to @form, alert: @field.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @field.update(field_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@field, partial: "form_fields/form_field", locals: { field: @field })
        end
        format.html { redirect_to @form, notice: "Campo actualizado." }
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @field.destroy!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@field) }
      format.html { redirect_to @form, notice: "Campo eliminado." }
    end
  end

  def duplicate
    copy = @field.duplicate!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.after(@field, partial: "form_fields/form_field", locals: { field: copy })
      end
      format.html { redirect_to @form }
    end
  end

  def reorder
    ids = Array(params[:ids]).map(&:to_i)
    fields = @form.fields.where(id: ids).index_by(&:id)
    FormField.transaction do
      ids.each_with_index { |id, i| fields[id]&.update_column(:position, i + 1) }
    end
    head :no_content
  end

  def apply_preset
    preset = FieldPresets::PRESETS[params[:preset]]
    return redirect_to(@form, alert: "No encontramos ese bloque.") unless preset

    existing = @form.fields.to_a
    added = []
    skipped = []

    FormField.transaction do
      preset[:fields].each do |attrs|
        if already_in_form?(existing, attrs)
          skipped << attrs[:label]
        else
          existing << @form.fields.create!(attrs.except(:options).merge(options_text: Array(attrs[:options]).join("\n")))
          added << attrs[:label]
        end
      end
    end

    redirect_to @form, notice: preset_notice(preset, added, skipped)
  end

  private

  def default_label(field)
    return "Nueva pregunta" unless field.section?
    field.starts_page? ? "Nueva página" : "Nueva sección"
  end

  def already_in_form?(existing, attrs)
    label = attrs[:label].parameterize
    existing.any? do |field|
      field.label.parameterize == label ||
        (FormField::SINGLE_IN_PRESETS.include?(attrs[:field_type]) && field.field_type == attrs[:field_type])
    end
  end

  def preset_notice(preset, added, skipped)
    if added.empty?
      return "Todas las preguntas del bloque \"#{preset[:name]}\" ya estaban en el formulario."
    end

    message = "Se #{added.size == 1 ? 'agregó 1 pregunta' : "agregaron #{added.size} preguntas"} del bloque \"#{preset[:name]}\"."
    message += " Se omitieron porque ya estaban: #{skipped.to_sentence}." if skipped.any?
    message
  end

  def set_form
    @form = Form.find_by!(public_id: params[:form_id])
    @area = @form.area
    @organization = @area.organization
  end

  def set_field
    @field = @form.fields.find(params[:id])
  end

  def field_params
    params.require(:form_field).permit(
      *EDITABLE,
      options_attributes: %i[id label position _destroy image remove_image]
    )
  end
end