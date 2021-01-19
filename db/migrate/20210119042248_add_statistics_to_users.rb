class AddStatisticsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :statistics, :jsonb, default: '{}'
    add_index :users, :statistics, using: :gin

    User.find_each do |user|
      user.update_statistics_cache
    end
  end
end
