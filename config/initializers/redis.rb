# config/initializers/redis.rb

if Rails.env.production? && ENV['REDIS_URL']
  # Configurar Redis para ActionCable en Heroku
  redis_url = ENV['REDIS_URL']
  
  # Extraer la URL base sin el esquema SSL
  redis_config = {
    url: redis_url,
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  }
  
  # Configurar ActionCable para usar Redis con SSL
  Rails.application.config.after_initialize do
    ActionCable.server.config.cable = {
      adapter: 'redis',
      url: redis_url,
      channel_prefix: 'interestelar_api_production',
      ssl_params: {
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
    }
  end
end