class AddRequestAtToPrsAccount < ActiveRecord::Migration[6.1]
  def change
    add_column :prs_accounts, :request_allow_at, :datetime
    add_column :prs_accounts, :request_denny_at, :datetime
  end
end
