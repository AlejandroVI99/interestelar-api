class AddLoyverseFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :receipt_number, :string
    add_column :payments, :loyverse_receipt_id, :string
    add_column :payments, :modifiers, :jsonb, default: []
    
    add_index :payments, :receipt_number
    add_index :payments, :loyverse_receipt_id
    add_index :payments, :modifiers, using: :gin
  end
end
