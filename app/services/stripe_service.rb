class StripeService
  def initialize
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end

  def create_payment_intent(amount:, item_id:, item_name:, currency: 'usd', user_id: nil)
    Stripe::PaymentIntent.create({
      amount: amount,
      currency: currency,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        item_id: item_id,
        item_name: item_name,
        user_id: user_id,
        created_at: Time.current.to_s
      }
    })
  end

  def process_payment_with_token(amount:, item_id:, item_name:, token:, user_id: nil)
    Stripe::PaymentIntent.create({
      amount: amount,
      currency: 'usd',
      payment_method_data: {
        type: 'card',
        card: { token: token }
      },
      confirm: true,
      metadata: {
        item_id: item_id,
        item_name: item_name,
        user_id: user_id,
        processed_from_backend: true
      }
    })
  end

  def process_payment_with_method(amount:, item_id:, item_name:, payment_method_id:, user_id: nil)
    Stripe::PaymentIntent.create({
      amount: amount,
      currency: 'usd',
      payment_method: payment_method_id,
      confirm: true,
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never'
      },
      metadata: {
        item_id: item_id,
        item_name: item_name,
        user_id: user_id
      }
    })
  end

  def confirm_payment(payment_intent_id)
    Stripe::PaymentIntent.retrieve(payment_intent_id)
  end

  def cancel_payment_intent(payment_intent_id)
    Stripe::PaymentIntent.cancel(payment_intent_id)
  end
end