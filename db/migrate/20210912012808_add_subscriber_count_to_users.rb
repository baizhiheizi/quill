class AddSubscriberCountToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :subscribers_count, :integer, default: 0
    add_column :users, :subscribing_count, :integer, default: 0
  end
end
