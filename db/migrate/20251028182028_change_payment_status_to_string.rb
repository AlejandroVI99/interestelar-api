class ChangePaymentStatusToString < ActiveRecord::Migration[8.0]
  def up
    change_column :payments, :status, :string
    
    Payment.where(status: 0).update_all(status: 'succeeded')

  end

  def down
    change_column :payments, :status, :integer
  end
end
