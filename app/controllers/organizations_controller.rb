class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[show edit update destroy]

  def index
    @organizations = Organization.includes(:areas).order(:name)
  end

  def show
    @areas = @organization.areas.order(:name)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    if @organization.save
      redirect_to @organization, notice: "Organización creada."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to @organization, notice: "Organización actualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @organization.destroy!
    redirect_to organizations_path, notice: "Organización eliminada."
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end

  def organization_params
    params.expect(organization: [:name])
  end
end