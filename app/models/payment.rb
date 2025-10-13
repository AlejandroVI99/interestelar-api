class Payment < ApplicationRecord
  validates :stripe_payment_intent_id, presence: true, uniqueness: true
  validates :amount, presence: true
  validates :item_id, presence: true
  validates :item_name, presence: true
  validates :user_id, presence: true

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :successful, -> { where(status: 'succeeded') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }

  def amount_in_currency
    (amount / 100.0).round(2)
  end

  def succeeded?
    status == 'succeeded'
  end

  def pending?
    status == 'pending'
  end

  def failed?
    status == 'failed'
  end

  def to_api_response
    {
      id: id,
      payment_intent_id: stripe_payment_intent_id,
      amount: amount_in_currency,
      currency: currency,
      status: status,
      item: {
        id: item_id,
        name: item_name,
        data: item_data
      },
      user_id: user_id,
      created_at: created_at.iso8601,
      confirmed_at: confirmed_at&.iso8601,
      metadata: metadata
    }
  end
end