module LoyverseConcern
  extend ActiveSupport::Concern
  
  private
  
  def loyverse_service
    @loyverse_service ||= LoyverseService.new
  end
  
  def handle_loyverse_error(error)
    case error.message
    when /Unauthorized/
      render_error("API authentication failed", :unauthorized)
    when /Rate limit/
      render_error("Too many requests, please try again later", :too_many_requests)
    else
      render_error("Service temporarily unavailable", :service_unavailable)
    end
  end
end