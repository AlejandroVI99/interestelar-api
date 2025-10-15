class Api::V1::KitchenOrdersController < ApplicationController

  def pending

    payments = Payment.where(status: 'succeeded')
                     .where("metadata->>'kitchen_status' IS NULL OR metadata->>'kitchen_status' IN (?)", 
                            ['pending', 'in_progress'])
                     .order(created_at: :asc)
                     .limit(50)
    
    orders = payments.map do |payment|
      {
        id: payment.id,
        item_name: payment.item_name,
        item_data: payment.item_data,
        amount: payment.amount / 100.0, 
        user_id: payment.user_id,
        created_at: payment.created_at,
        status: payment.metadata&.dig('kitchen_status') || 'pending'
      }
    end
    
    render json: {
      success: true,
      data: {
        orders: orders,
        total: orders.count
      }
    }
  rescue => e
    Rails.logger.error "Error fetching pending orders: #{e.message}"
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  def update_status
    payment = Payment.find(params[:id])
    
    new_status = params[:status]
    
    unless ['pending', 'in_progress', 'completed'].include?(new_status)
      return render json: {
        success: false,
        error: 'Estado inválido. Debe ser: pending, in_progress o completed'
      }, status: :bad_request
    end
    
    # Actualizar metadata
    current_metadata = payment.metadata || {}
    updated_metadata = current_metadata.merge(
      'kitchen_status' => new_status,
      'kitchen_updated_at' => Time.current.iso8601
    )
    
    payment.update!(metadata: updated_metadata)
    
    # Broadcast a todos los clientes conectados
    ActionCable.server.broadcast('kitchen_orders', {
      type: 'order_updated',
      order: {
        id: payment.id,
        status: new_status,
        updated_at: Time.current
      }
    })
    
    Rails.logger.info "Kitchen order #{payment.id} updated to #{new_status}"
    
    render json: {
      success: true,
      data: {
        message: 'Estado actualizado correctamente',
        order: {
          id: payment.id,
          status: new_status
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Orden no encontrada'
    }, status: :not_found
  rescue => e
    Rails.logger.error "Error updating order status: #{e.message}"
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end
end