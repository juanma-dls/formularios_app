class PublicFormsController < ApplicationController
  layout "public"
  before_action :set_form

  def show
    return render_unavailable unless @form.published?
    @values = {}
  end

  def create
    return render_unavailable unless @form.published?
    
    return redirect_to(public_form_thanks_path(@form.public_id)) if params[:website].present?

    @values = answer_params.to_h
    @submission = Submission.build_from(@form, @values)

    if @submission.save
      redirect_to public_form_thanks_path(@form.public_id)
    else
      render :show, status: :unprocessable_content
    end
  end

  def thanks
  end

  private

  def set_form
    @form = Form.includes(fields: :options).find_by!(public_id: params[:public_id])
  end

  def answer_params
    permitted = @form.fields.map do |field|
      field.field_type == "multiple_choice" ? { field.key => [] } : field.key
    end
    params.fetch(:answers, {}).permit(*permitted)
  end

  def render_unavailable
    render :unavailable, status: (@form.closed? ? :ok : :not_found)
  end
end