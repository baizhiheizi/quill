class MigratePaymentsPayerId < ActiveRecord::Migration[6.1]
  def change
    Payment.find_each do |payment|
      payment.update payer_id: payment.opponent_id
    end
  end
end
