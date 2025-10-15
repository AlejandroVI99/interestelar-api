class LoyverseService
  include HTTParty
  base_uri 'https://api.loyverse.com/v1.0'

  def initialize
    @token = ENV['LOYVERSE_API_TOKEN']
    @store_id = ENV['LOYVERSE_STORE_ID']
    @pos_device_id = ENV['LOYVERSE_POS_DEVICE_ID']
    @headers = {
      'Authorization' => "Bearer #{@token}",
      'Content-Type' => 'application/json'
    }
  end

  def get_item(item_id)
    response = self.class.get("/items/#{item_id}", headers: @headers)
    
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Loyverse API Error: #{response.code} - #{response.message}"
      nil
    end
  end

  def get_all_items
    response = self.class.get('/items', headers: @headers)
    
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Loyverse API Error: #{response.code} - #{response.message}"
      []
    end
  end

  # Obtener modificadores disponibles
  def get_modifiers
    response = self.class.get('/modifiers', headers: @headers)
    
    if response.success?
      response.parsed_response['modifiers']
    else
      Rails.logger.error "Loyverse Modifiers Error: #{response.code} - #{response.message}"
      []
    end
  end

  # Crear receipt
  def create_receipt(payment_data)
    # Construir line_modifiers con el formato correcto
    line_modifiers = payment_data[:modifiers]&.map do |mod|
      {
        modifier_option_id: mod['modifier_option_id'], # REQUERIDO por Loyverse
        quantity: 1
      }
    end || []

    line_items = [{
      item_id: payment_data[:item_id],
      variant_id: payment_data[:variant_id], # IMPORTANTE: Agregar variant_id
      quantity: 1,
      price: payment_data[:price],
      line_modifiers: line_modifiers
    }]

    body = {
      source: "API",
      receipt_type: "SELL",
      created_at: Time.current.iso8601,
      store_id: @store_id.present? ? @store_id : "nil",
      line_items: line_items,
      payments: [{
        payment_type_id: ENV['LOYVERSE_CARD_PAYMENT_TYPE_ID'],
        paid_at: Time.current.iso8601,
        paid_amount: payment_data[:total_amount]
      }],
      note: "Usuario: #{payment_data[:user_id]} | Stripe: #{payment_data[:payment_intent_id]}"
    }

    Rails.logger.info "Creating Loyverse receipt with body: #{body.to_json}"

    response = self.class.post('/receipts', 
      headers: @headers,
      body: body.to_json
    )
    
    if response.success?
      Rails.logger.info "Loyverse receipt created: #{response.parsed_response}"
      response.parsed_response
    else
      Rails.logger.error "Loyverse Receipt Error: #{response.code} - #{response.body}"
      nil
    end
  end
end