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
    @fields = @form.fields.includes(options: { image_attachment: :blob })
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
      return redirect_to @form, alert: "Agregá al menos un campo antes de publicar."
    end
    if @form.effective_spreadsheet_id.blank?
      return redirect_to @form, alert: "Conectá una planilla de Google antes de publicar."
    end

    # Si cambió la planilla desde la última publicación, se empieza en una pestaña nueva
    if @form.synced_spreadsheet_id != @form.effective_spreadsheet_id
      @form.update!(synced_spreadsheet_id: nil, sheet_gid: nil)
    end

    if FormSheetSync.call(@form)
      @form.update!(status: :published, closed_at: nil, backup_sent_at: nil)
      redirect_to @form, notice: "Formulario publicado. Las respuestas se guardan en la pestaña \"#{@form.sheet_title}\"."
    else
      redirect_to @form, alert: "No se pudo preparar la planilla: #{@form.last_sync_error}"
    end
  end

  def sync
    SyncFormJob.perform_later(@form.id)
    redirect_to @form, notice: "Sincronización en curso. Recargá en unos segundos para ver el resultado."
  end

  def close
    @form.update!(status: :closed, closed_at: Time.current, backup_sent_at: nil)
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
    params.expect(form: [:title, :description, :success_message, :captcha_enabled, :terms_required, :terms_document])
  end
end