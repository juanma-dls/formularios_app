class SyncPendingSubmissionsJob < ApplicationJob
  def perform
    form_ids = Submission.where(synced_at: nil, purged_at: nil).distinct.pluck(:form_id)
    Form.where(id: form_ids).includes(area: :organization).find_each do |form|
      SyncFormJob.perform_later(form.id) if form.syncable?
    end
  end
end