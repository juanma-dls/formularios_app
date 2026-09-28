class PurgeSyncedSubmissionsJob < ApplicationJob
  def perform
    Form.closed.where(data_purged_at: nil).where.not(archive_generated_at: nil).find_each do |form|
      due = form.purge_scheduled_at
      next unless due && due <= Time.current
      # Si tiene planilla y quedan respuestas por enviar, esperar a que se sincronicen
      next if form.sheet_gid && form.submissions.where(synced_at: nil).exists?

      purge!(form)
    end
  end

  private

  def purge!(form)
    form.submissions.where(purged_at: nil).in_batches(of: 1000) do |batch|
      batch.update_all(answers: {}, purged_at: Time.current)
    end
    form.archive.purge
    form.update!(data_purged_at: Time.current)
  end
end