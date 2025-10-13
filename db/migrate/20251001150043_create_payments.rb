class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.string :user_id, null: false
      t.string :stripe_payment_intent_id, null: false
      t.integer :amount, null: false
      t.string :currency
      t.integer :status, default: 0
      t.string :item_id, null: false
      t.string :item_name, null: false
      t.jsonb :item_data
      t.jsonb :metadata
      t.timestamp :confirmed_at
      t.timestamps
    end

    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :status
    add_index :payments, :item_id
    add_index :payments, :created_at
    add_index :payments, :confirmed_at
    add_index :payments, :user_id

    add_index :payments, :item_data, using: :gin
    add_index :payments, :metadata, using: :gin
  end
end

