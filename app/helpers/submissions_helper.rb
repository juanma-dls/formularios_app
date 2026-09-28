module SubmissionsHelper
  def display_answer(field, value)
    return value.join(", ") if value.is_a?(Array)
    return value if value.blank?

    if field.field_type == "date"
      Date.iso8601(value).strftime("%d/%m/%Y")
    else
      value
    end
  rescue Date::Error
    value
  end
end