class ApplicationController < ActionController::API
  before_action :authenticate_api_token
  
  private
  
  def authenticate_api_token
    expected_token = ENV['MY_API_TOKEN']
    
    # Validar que el token de entorno exista
    if expected_token.blank?
      Rails.logger.error "❌ MY_API_TOKEN no está configurado en el .env"
      render json: { 
        success: false,
        error: 'Error de configuración del servidor',
        timestamp: Time.current.iso8601
      }, status: :internal_server_error
      return
    end
    
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    # Validar que el token recibido exista y coincida
    if token.blank? || token != expected_token
      render json: { 
        success: false,
        error: 'Token inválido o no autorizado',
        timestamp: Time.current.iso8601
      }, status: :unauthorized
      return
    end
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { 
      success: false,
      error: message,
      timestamp: Time.current.iso8601
    }, status: status
  end
  
  def render_success(data, message = nil)
    response = { 
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }
    response[:message] = message if message
    render json: response
  end
end