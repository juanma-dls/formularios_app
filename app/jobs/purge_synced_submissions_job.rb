class PurgeSyncedSubmissionsJob < ApplicationJob
  # Días que se conservan los datos después de llegar a la planilla
  RETENTION_DAYS = ENV.fetch("SUBMISSION_RETENTION_DAYS", 30).to_i

  def perform
    forms = Form.closed
                .where(closed_at: ..RETENTION_DAYS.days.ago)
                .where.not(backup_sent_at: nil)

    Submission.where(form_id: forms.select(:id), purged_at: nil)
              .where.not(synced_at: nil)
              .in_batches(of: 1000) do |batch|
      batch.update_all(answers: {}, purged_at: Time.current)
    end
  end
end