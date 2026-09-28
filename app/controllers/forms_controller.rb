class FormsController < ApplicationController
  before_action :set_area, only: %i[index new create]
  before_action :set_form, only: %i[show edit update destroy publish close preview]

  def index
    @forms = @area.forms.includes(:fields).order(created_at: :desc)
  end

  def new
    @form = @area.forms.new
  end

  def create
    @form = @area.forms.new(form_params)
    if @form.save
      redirect_to @form, notice: "Formulario creado. Ahora agregale campos."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @fields = @form.fields.includes(:options)
  end

  def edit
  end

  def update
    if @form.update(form_params)
      redirect_to @form, notice: "Formulario actualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @form.destroy!
    redirect_to organization_area_forms_path(@organization, @area), notice: "Formulario eliminado."
  end

  def publish
    if @form.fields.empty?
      redirect_to @form, alert: "Agregá al menos un campo antes de publicar."
    elsif @form.effective_spreadsheet_id.blank?
      redirect_to @form, alert: "Conectá una planilla de Google antes de publicar."
    else
      @form.published!
      redirect_to @form, notice: "Formulario publicado."
    end
  end

  def close
    @form.closed!
    redirect_to @form, notice: "Formulario cerrado. Ya no recibe respuestas."
  end

  def preview
    @preview = true
    @values = {}
    render "public_forms/show", layout: "public"
  end

  private

  def set_area
    @organization = Organization.find_by!(slug: params[:organization_id])
    @area = @organization.areas.find_by!(slug: params[:area_id])
  end

  def set_form
    @form = Form.find_by!(public_id: params[:id])
    @area = @form.area
    @organization = @area.organization
  end

  def form_params
    params.expect(form: [:title, :description, :success_message])
  end
end