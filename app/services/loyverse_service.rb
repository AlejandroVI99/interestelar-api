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
    # payment_data[:items] es un array de items
    # Cada item tiene: item_id, variant_id, quantity, price, modifiers
    line_items = payment_data[:items].map do |item|
      line_modifiers = item[:modifiers]&.map do |mod|
        {
          modifier_option_id: mod['modifier_option_id'],
          quantity: mod['quantity'] || 1
        }
      end || []

      {
        item_id: item[:item_id],
        variant_id: item[:variant_id],
        quantity: item[:quantity] || 1,
        price: item[:price],
        line_modifiers: line_modifiers
      }
    end

    body = {
      source: "API",
      receipt_type: "SALE",
      created_at: Time.current.iso8601,
      store_id: payment_data[:store_id],
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