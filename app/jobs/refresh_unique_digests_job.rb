class RefreshUniqueDigestsJob < ApplicationJob
  def perform(form_id)
    form = Form.find_by(id: form_id)
    return unless form

    active = form.submissions.where(purged_at: nil)
    active.update_all(unique_digest: nil)

    field = form.fields.find_by(unique_answer: true)
    return unless field

    # Las huellas de respuestas depuradas se conservan y cuentan como tomadas
    taken = form.submissions.where.not(purged_at: nil).where.not(unique_digest: nil).pluck(:unique_digest).to_set

    active.order(:id).find_each do |submission|
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