class SyncPendingSubmissionsJob < ApplicationJob
  def perform
    Submission.where(synced_at: nil).distinct.pluck(:form_id).each do |form_id|
      SyncFormJob.perform_later(form_id)
    end
  end
end