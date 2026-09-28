class RefreshUniqueDigestsJob < ApplicationJob
  def perform(form_id)
    form = Form.find_by(id: form_id)
    return unless form

    form.submissions.update_all(unique_digest: nil)

    field = form.fields.find_by(unique_answer: true)
    return unless field

    taken = Set.new
    form.submissions.order(:id).find_each do |submission|
      value = submission.answers[field.key]
      next if value.blank?

      digest = Submission.digest_for(form.id, value)
      next unless taken.add?(digest)

      submission.update_column(:unique_digest, digest)
    rescue ActiveRecord::RecordNotUnique
      next
    end
  end
end