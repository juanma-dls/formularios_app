class FormFieldsController < ApplicationController
  EDITABLE = %i[label help_text required unique_answer options_text].freeze

  before_action :set_form
  before_action :set_field, except: %i[new create]

  def new
    type = params[:field_type].presence_in(FormField::TYPES.keys) || "short_text"
    @field = @form.fields.new(field_type: type)
  end

  def create
    @field = @form.fields.new(params.expect(form_field: [:field_type, *EDITABLE]))
    if @field.save
      redirect_to @form, notice: "Campo agregado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @field.update(params.expect(form_field: EDITABLE))
      redirect_to @form, notice: "Campo actualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @field.destroy!
    redirect_to @form, notice: "Campo eliminado."
  end

  def move_up
    @field.move!(:up)
    redirect_to @form
  end

  def move_down
    @field.move!(:down)
    redirect_to @form
  end

  private

  def set_form
    @form = Form.find_by!(public_id: params[:form_id])
    @area = @form.area
    @organization = @area.organization
  end

  def set_field
    @field = @form.fields.find(params[:id])
  end
end