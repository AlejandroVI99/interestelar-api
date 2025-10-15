# app/channels/kitchen_channel.rb
class KitchenChannel < ApplicationCable::Channel
  def subscribed
    stream_from "kitchen_orders"
    Rails.logger.info "Client subscribed to kitchen_orders channel"
  end

  def unsubscribed
    stop_all_streams
    Rails.logger.info "Client unsubscribed from kitchen_orders channel"
  end
end