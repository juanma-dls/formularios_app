class FormResults
  def initialize(form)
    @form = form
    @choice_fields = form.fields.select(&:choice?)
  end

  def call
    counts = @choice_fields.to_h { |field| [field.key, Hash.new(0)] }
    total = 0

    @form.submissions.where(purged_at: nil).find_each do |submission|
      total += 1
      @choice_fields.each do |field|
        Array(submission.answers[field.key]).each { |value| counts[field.key][value] += 1 }
      end
    end

    {
      "total" => total,
      "fields" => @choice_fields.map do |field|
        {
          "label" => field.label,
          "options" => field.options.map { |o| { "label" => o.label, "count" => counts[field.key][o.label] } }
        }
      end
    }
  end
end