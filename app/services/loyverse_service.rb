class LoyverseService
  include HTTParty
  base_uri 'https://api.loyverse.com/v1.0'

  def initialize
    @token = ENV['LOYVERSE_API_TOKEN']
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
end