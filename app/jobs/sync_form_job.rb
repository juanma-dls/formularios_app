class SyncFormJob < ApplicationJob
  limits_concurrency to: 1, key: ->(form_id) { "sync_form_#{form_id}" }, duration: 10.minutes

  def perform(form_id)
    form = Form.find_by(id: form_id)
    FormSheetSync.call(form) if form&.syncable?
  end
end