class AddConterCacheForTagSubscribers < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :subscribers_count, :integer, default: 0
  end
end
