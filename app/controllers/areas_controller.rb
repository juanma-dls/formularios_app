class AreasController < ApplicationController
  before_action :set_organization
  before_action :set_area, only: %i[edit update destroy]

  def new
    @area = @organization.areas.new
  end

  def create
    @area = @organization.areas.new(area_params)
    if @area.save
      redirect_to @organization, notice: "Área creada."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @area.update(area_params)
      redirect_to @organization, notice: "Área actualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @area.destroy!
    redirect_to @organization, notice: "Área eliminada."
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:organization_id])
  end

  def set_area
    @area = @organization.areas.find_by!(slug: params[:id])
  end

  def area_params
    params.expect(area: [:name])
  end
end