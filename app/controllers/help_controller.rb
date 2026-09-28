class HelpController < ApplicationController
  def spreadsheets
    @service_account_email = begin
      GoogleSheets.service_account_email
    rescue GoogleSheets::Error
      nil
    end
  end
end