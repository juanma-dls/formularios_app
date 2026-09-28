class PublicFormsController < ApplicationController
  MIN_SECONDS_TO_SUBMIT = 2

  layout "public"
  before_action :set_form
  helper_method :timing_token

  def show
    return render_unavailable unless @form.published?
    @values = {}
  end

  def create
    return render_unavailable unless @form.published?

    return redirect_to(public_form_thanks_path(@form.public_id)) if params[:website].present? || too_fast?

    @values = answer_params.to_h

    if @form.captcha_enabled? && !TurnstileVerifier.verify(params["cf-turnstile-response"], request.remote_ip)
      @captcha_error = "No pudimos verificar que seas una persona. Completá la verificación y volvé a enviar."
      return render :show, status: :unprocessable_content
    end

    @submission = Submission.build_from(@form, @values, accept_terms: params[:accept_terms] == "1")

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
    @form = Form.with_attached_terms_document
                .includes(fields: { options: { image_attachment: :blob } },
                          area: { organization: [{ logo_attachment: :blob }, { banner_attachment: :blob }] })
                .find_by!(public_id: params[:public_id])
    @organization = @form.organization
  end

  def answer_params
    permitted = @form.fields.map do |field|
      field.field_type == "multiple_choice" ? { field.key => [] } : field.key
    end
    params.fetch(:answers, {}).permit(*permitted)
  end

  def render_unavailable
    render :unavailable, status: (@form.draft? ? :not_found : :ok)
  end

  # Marca de tiempo firmada: registra cuándo se abrió el formulario
  def timing_token
    timing_verifier.generate(Time.current.to_f)
  end

  def too_fast?
    started_at = timing_verifier.verified(params[:t].to_s)
    started_at.present? && (Time.current.to_f - started_at) < MIN_SECONDS_TO_SUBMIT
  end

  def timing_verifier
    Rails.application.message_verifier(:form_timing)
  end
end