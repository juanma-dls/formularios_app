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
      sheet = service.get_spreadsheet(spreadsheet_id, fields: "properties.title")

      temp_id = SecureRandom.random_number(1_000_000_000)
      requests = [
        S::Request.new(add_sheet: S::AddSheetRequest.new(
          properties: S::SheetProperties.new(sheet_id: temp_id, title: "_verificacion_#{temp_id}")
        )),
        S::Request.new(delete_sheet: S::DeleteSheetRequest.new(sheet_id: temp_id))
      ]
      service.batch_update_spreadsheet(spreadsheet_id, S::BatchUpdateSpreadsheetRequest.new(requests: requests))

      sheet.properties.title
    rescue Google::Apis::ClientError => e
      raise Error, client_error_message(e)
    rescue Google::Apis::AuthorizationError
      raise Error, "Las credenciales de la cuenta de servicio no son válidas. Revisá la configuración del servidor."
    rescue Google::Apis::ServerError, Google::Apis::TransmissionError
      raise Error, "Google no respondió. Probá de nuevo en unos minutos."
    end

    def service
      @service ||= S::SheetsService.new.tap do |s|
        s.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(credentials_hash.to_json),
          scope: S::AUTH_SPREADSHEETS
        )
      end
    end

    private

    def credentials_hash
      @credentials_hash ||= begin
        json = Rails.application.credentials.dig(:google, :service_account_json)
        raise Error, "Falta configurar la cuenta de servicio de Google en las credenciales." if json.blank?
        JSON.parse(json)
      end
    end

    def client_error_message(e)
      if e.message.include?("SERVICE_DISABLED") || e.message.include?("has not been used")
        return "La API de Google Sheets no está habilitada en el proyecto de Google Cloud."
      end

      case e.status_code
      when 403 then "La app no tiene permiso de editor. Compartí la planilla con #{service_account_email} como Editor."
      when 404 then "No encontramos esa planilla. Revisá el enlace."
      else "Google rechazó la solicitud (código #{e.status_code})."
      end
    end
  end
end