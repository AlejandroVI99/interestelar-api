class Api::V1::ItemsController < ApplicationController
  before_action :initialize_loyverse_service

  # GET /api/v1/items
  def index
    items = @loyverse_service.get_all_items
    
    if items
      render_success({ items: items }, "Items obtenidos exitosamente")
    else
      render_error("No se pudieron obtener los items", :service_unavailable)
    end
  end

  # GET /api/v1/items/:id
  def show
    item = @loyverse_service.get_item(params[:id])
    
    if item
      render_success({ item: item })
    else
      render_error("Item no encontrado o error del servicio", :not_found)
    end
  end

  private

  def initialize_loyverse_service
    @loyverse_service = LoyverseService.new
  end
end