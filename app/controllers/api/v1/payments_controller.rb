class Api::V1::PaymentsController < ApplicationController
  before_action :initialize_services
  before_action :validate_user_id, only: [:process_payment_with_token, :process_payment_with_method]

  # POST /api/v1/payments/process_with_token
  def process_payment_with_token
    begin
      # Obtener item de Loyverse
      item = @loyverse_service.get_item(params[:item_id])
      return render_error('Artículo no encontrado') unless item

      token = params[:token]
      return render_error('Token de pago requerido') if token.blank?

      amount = calculate_amount(params[:amount] || item['default_price'] || 6.0)

      # Crear payment intent
      payment_intent = Stripe::PaymentIntent.create({
        amount: amount,
        currency: params[:currency] || 'usd',
        payment_method_data: {
          type: 'card',
          card: { token: token }
        },
        confirm: true,
        automatic_payment_methods: {
          enabled: true,
          allow_redirects: 'never'
        },
        metadata: {
          item_id: params[:item_id],
          item_name: item['item_name'],
          user_id: params[:user_id],
          processed_from_backend: true
        }
      })

      # Guardar en base de datos
      payment = Payment.create!(
        stripe_payment_intent_id: payment_intent.id,
        amount: payment_intent.amount,
        currency: payment_intent.currency,
        status: map_stripe_status(payment_intent.status),
        item_id: params[:item_id],
        item_name: item['item_name'],
        item_data: item,
        user_id: params[:user_id],
        confirmed_at: payment_intent.status == 'succeeded' ? Time.current : nil,
        metadata: payment_intent.metadata.to_h
      )

      Rails.logger.info "Payment #{payment.id} created for user #{params[:user_id]}"
      if payment_intent.status == 'succeeded'
        # Hacer broadcast a la cocina
        ActionCable.server.broadcast('kitchen_orders', {
          type: 'new_order',
          order: {
            id: payment.id,
            item_name: payment.item_name,
            item_data: payment.item_data,
            amount: payment.amount / 100.0,
            user_id: payment.user_id,
            created_at: payment.created_at,
            status: 'pending'
          }
        })
        
        Rails.logger.info "New order broadcasted to kitchen: #{payment.id}"
      end
      render_success({
        payment_id: payment.id,
        payment_intent_id: payment_intent.id,
        status: payment_intent.status,
        amount: payment.amount_in_currency,
        currency: payment.currency,
        item: item,
        user_id: payment.user_id
      }, payment_status_message(payment_intent.status))

    rescue Stripe::CardError => e
      render_error("Error de tarjeta: #{e.message}")
    rescue Stripe::StripeError => e
      render_error("Error de Stripe: #{e.message}")
    rescue => e
      Rails.logger.error "Payment error: #{e.message}"
      render_error("Error al procesar pago: #{e.message}")
    end
  end

  # POST /api/v1/payments/process_with_method
  def process_payment_with_method
    begin
      item = @loyverse_service.get_item(params[:item_id])
      return render_error('Artículo no encontrado') unless item

      payment_method_id = params[:payment_method_id]
      return render_error('Payment Method ID requerido') if payment_method_id.blank?

      amount = calculate_amount(params[:price])

      payment_intent = Stripe::PaymentIntent.create({
        amount: amount,
        currency: 'MXN',
        payment_method: payment_method_id,
        confirm: true,
        automatic_payment_methods: {
          enabled: true,
          allow_redirects: 'never'
        },
        metadata: {
          item_id: params[:item_id],
          item_name: item['item_name'],
          user_id: params[:user_id]
        }
      })

      payment = Payment.create!(
        stripe_payment_intent_id: payment_intent.id,
        amount: payment_intent.amount,
        currency: payment_intent.currency,
        status: map_stripe_status(payment_intent.status),
        item_id: params[:item_id],
        item_name: item['item_name'],
        item_data: item,
        user_id: params[:user_id],
        modifiers: params[:modifiers] || [],
        confirmed_at: payment_intent.status == 'succeeded' ? Time.current : nil,
        metadata: payment_intent.metadata.to_h
      )

      if payment_intent.status == 'succeeded'
        loyverse_receipt = @loyverse_service.create_receipt({
          item_id: params[:item_id],
          variant_id: params[:variant_id],
          price: params[:price],
          modifiers: params[:modifiers],
          total_amount: params[:price],
          user_id: params[:user_id],
          payment_intent_id: payment_intent.id
        })

        if loyverse_receipt
          payment.update!(
            receipt_number: loyverse_receipt['receipt_number'],
            loyverse_receipt_id: loyverse_receipt['receipt_id']
          )

          ActionCable.server.broadcast('kitchen_orders', {
            type: 'new_order',
            order: {
              id: payment.id,
              order_number: loyverse_receipt['receipt_number'],
              item_name: payment.item_name,
              modifiers: payment.modifiers,
              amount: payment.amount / 100.0,
              user_id: payment.user_id,
              created_at: payment.created_at,
              status: 'pending'
            }
          })
          
          Rails.logger.info "Order #{loyverse_receipt['receipt_number']} sent to kitchen"
        else
          Rails.logger.warn "Payment successful but Loyverse receipt failed for payment #{payment.id}"
        end
      end

      render_success({
        payment_id: payment.id,
        payment_intent_id: payment_intent.id,
        order_number: payment.receipt_number,
        status: payment_intent.status,
        amount: payment.amount_in_currency,
        currency: payment.currency
      }, payment_status_message(payment_intent.status))

    rescue Stripe::CardError => e
      render_error("Error de tarjeta: #{e.message}")
    rescue Stripe::StripeError => e
      render_error("Error de Stripe: #{e.message}")
    rescue => e
      Rails.logger.error "Payment error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render_error("Error al procesar pago: #{e.message}")
    end
  end

  # GET /api/v1/payments/user/:user_id
  def by_user
    user_id = params[:user_id]
    return render_error('user_id requerido', :bad_request) if user_id.blank?

    payments = Payment.where(user_id: user_id)
                     .order(created_at: :desc)
                     .limit(params[:limit] || 100)

    render_success({
      user_id: user_id,
      total_payments: payments.count,
      payments: payments.map(&:to_api_response)
    })
  end

  # GET /api/v1/payments/:id
  def show
    payment = Payment.find_by(id: params[:id])
    
    if payment
      render_success({ payment: payment.to_api_response })
    else
      render_error("Pago no encontrado", :not_found)
    end
  end

  # GET /api/v1/payments
  def index
    payments = Payment.order(created_at: :desc)
                     .limit(params[:limit] || 100)

    render_success({
      total_payments: payments.count,
      payments: payments.map(&:to_api_response)
    })
  end

  private

  def initialize_services
    @loyverse_service = LoyverseService.new
    @stripe_service = StripeService.new
  end

  def validate_user_id
    if params[:user_id].blank?
      render_error('user_id es requerido', :bad_request)
      return
    end
  end

  def calculate_amount(price)
    (price.to_f * 100).to_i
  end

  def map_stripe_status(stripe_status)
    case stripe_status
    when 'succeeded'
      'succeeded'
    when 'requires_payment_method', 'requires_confirmation', 'requires_action'
      'pending'
    when 'canceled'
      'canceled'
    else
      'failed'
    end
  end

  def payment_status_message(status)
    case status
    when 'succeeded'
      '¡Pago procesado exitosamente!'
    when 'requires_action'
      'El pago requiere autenticación adicional'
    when 'requires_payment_method'
      'Método de pago requerido'
    when 'canceled'
      'Pago cancelado'
    else
      'Pago fallido'
    end
  end
end