module SpreadsheetConnectable
  extend ActiveSupport::Concern

  def spreadsheet_connected?
    spreadsheet_id.present?
  end

  def spreadsheet_url
    "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/edit" if spreadsheet_connected?
  end

  def connect_spreadsheet!(url_or_id)
    id = GoogleSheets.extract_id(url_or_id)
    raise GoogleSheets::Error, "El enlace no parece ser de una planilla de Google." if id.nil?

    title = GoogleSheets.verify_access!(id)
    update!(spreadsheet_id: id, spreadsheet_title: title, spreadsheet_connected_at: Time.current)
  end

  def disconnect_spreadsheet!
    update!(spreadsheet_id: nil, spreadsheet_title: nil, spreadsheet_connected_at: nil)
  end
end