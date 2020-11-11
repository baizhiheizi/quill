class AddCounterCacheForActionStore < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :authoring_subscribers_count, :integer, default: 0
    add_column :users, :reading_subscribers_count, :integer, default: 0
    add_column :articles, :commenting_subscribers_count, :integer, default: 0
  end
end
