class SpreadsheetConnectionsController < ApplicationController
  before_action :set_owner

  def new
  end

  def create
    @owner.connect_spreadsheet!(params[:spreadsheet_url])
    redirect_to @organization, notice: "Planilla \"#{@owner.spreadsheet_title}\" conectada."
  rescue GoogleSheets::Error => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_content
  end

  def destroy
    @owner.disconnect_spreadsheet!
    redirect_to @organization, notice: "Planilla desconectada."
  end

  private

  def set_owner
    @organization = Organization.find_by!(slug: params[:organization_id])
    @area = @organization.areas.find_by!(slug: params[:area_id]) if params[:area_id]
    @owner = @area || @organization
  end
end