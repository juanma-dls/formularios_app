require "google/apis/sheets_v4"
require "googleauth"

class GoogleSheets
  class Error < StandardError; end

  S = Google::Apis::SheetsV4
  ID_FROM_URL = %r{/spreadsheets/d/([a-zA-Z0-9_-]{20,})}
  RAW_ID = /\A[a-zA-Z0-9_-]{20,}\z/

  class << self
    def service_account_email
      credentials_hash.fetch("client_email")
    end

    def extract_id(input)
      value = input.to_s.strip
      value[ID_FROM_URL, 1] || (value.match?(RAW_ID) ? value : nil)
    end

    # Verifica lectura y escritura. Devuelve el título de la planilla.
    def verify_access!(spreadsheet_id)
      handle_errors do
        sheet = service.get_spreadsheet(spreadsheet_id, fields: "properties.title")
        temp_id = SecureRandom.random_number(1_000_000_000)
        batch_update(spreadsheet_id, [
          S::Request.new(add_sheet: S::AddSheetRequest.new(
            properties: S::SheetProperties.new(sheet_id: temp_id, title: "_verificacion_#{temp_id}")
          )),
          S::Request.new(delete_sheet: S::DeleteSheetRequest.new(sheet_id: temp_id))
        ])
        sheet.properties.title
      end
    end

    # { id_de_pestaña => título } de todas las pestañas
    def sheet_titles(spreadsheet_id)
      handle_errors do
        spreadsheet = service.get_spreadsheet(spreadsheet_id, fields: "sheets.properties(sheetId,title)")
        Array(spreadsheet.sheets).to_h { |s| [s.properties.sheet_id, s.properties.title] }
      end
    end

    # Crea una pestaña con la primera fila congelada. Devuelve su ID.
    def add_sheet!(spreadsheet_id, title)
      handle_errors do
        response = batch_update(spreadsheet_id, [
          S::Request.new(add_sheet: S::AddSheetRequest.new(
            properties: S::SheetProperties.new(
              title: title,
              grid_properties: S::GridProperties.new(frozen_row_count: 1)
            )
          ))
        ])
        response.replies.first.add_sheet.properties.sheet_id
      end
    end

    def update_values!(spreadsheet_id, range, rows)
      handle_errors do
        service.update_spreadsheet_value(spreadsheet_id, range, S::ValueRange.new(values: rows),
                                         value_input_option: "RAW")
      end
    end

    def append_values!(spreadsheet_id, range, rows)
      handle_errors do
        service.append_spreadsheet_value(spreadsheet_id, range, S::ValueRange.new(values: rows),
                                         value_input_option: "USER_ENTERED",
                                         insert_data_option: "INSERT_ROWS")
      end
    end

    private

    def service
      Thread.current[:google_sheets_service] ||= S::SheetsService.new.tap do |s|
        s.authorization = credentials
      end
    end

    def credentials
      @credentials ||= Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials_hash.to_json),
        scope: S::AUTH_SPREADSHEETS
      )
    end

    def credentials_hash
      @credentials_hash ||= begin
        json = Rails.application.credentials.dig(:google, :service_account_json)
        raise Error, "Falta configurar la cuenta de servicio de Google en las credenciales." if json.blank?
        JSON.parse(json)
      end
    end

    def batch_update(spreadsheet_id, requests)
      service.batch_update_spreadsheet(spreadsheet_id, S::BatchUpdateSpreadsheetRequest.new(requests: requests))
    end

    def handle_errors
      yield
    rescue Google::Apis::RateLimitError
      raise Error, "Google limitó temporalmente las solicitudes. Se reintenta automáticamente."
    rescue Google::Apis::ClientError => e
      raise Error, client_error_message(e)
    rescue Google::Apis::AuthorizationError
      raise Error, "Las credenciales de la cuenta de servicio no son válidas. Revisá la configuración del servidor."
    rescue Google::Apis::ServerError, Google::Apis::TransmissionError
      raise Error, "Google no respondió. Se reintenta automáticamente."
    end

    def client_error_message(e)
      if e.message.include?("SERVICE_DISABLED") || e.message.include?("has not been used")
        return "La API de Google Sheets no está habilitada en el proyecto de Google Cloud."
      end

      case e.status_code
      when 403 then "La app no tiene permiso de editor. Compartí la planilla con #{service_account_email} como Editor."
      when 404 then "No encontramos la planilla. Puede que la hayan borrado."
      else "Google rechazó la solicitud (código #{e.status_code}): #{e.message.truncate(200)}"
      end
    end
  end
end