class SubmissionsController < ApplicationController
  PER_PAGE = 50

  before_action :set_form

  def index
    @fields = @form.fields.select(&:input?)
    @columns = @fields.flat_map { |field| field.columns.map { |column| [field, column] } }
    scope = filtered(@form.submissions.where(purged_at: nil))

    @total = scope.count
    @pages = [(@total / PER_PAGE.to_f).ceil, 1].max
    @page = params[:page].to_i.clamp(1, @pages)
    @submissions = scope.order(id: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @fields = @form.fields.select(&:input?)
    @submission = @form.submissions.find(params[:id])
  end

  private

  def set_form
    @form = Form.find_by!(public_id: params[:form_id])
    @area = @form.area
    @organization = @area.organization
  end

  def filtered(scope)
    if (from = parse_date(params[:desde]))
      scope = scope.where(created_at: from.beginning_of_day..)
    end
    if (to = parse_date(params[:hasta]))
      scope = scope.where(created_at: ..to.end_of_day)
    end

    query = params[:q].to_s.strip
    return scope if query.empty?

    # Un DNI o teléfono con puntos o guiones se busca solo por sus números
    query = query.gsub(/\D/, "") if query.match?(/\A[\d.\s-]+\z/)
    like = "%#{Submission.sanitize_sql_like(query)}%"
    scope.where("CAST(answers AS CHAR) COLLATE utf8mb4_unicode_ci LIKE ? OR CAST(id AS CHAR) = ?", like, query)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end