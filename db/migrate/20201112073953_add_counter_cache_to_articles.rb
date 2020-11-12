class AddCounterCacheToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :upvotes_count, :integer, default: 0
    add_column :articles, :downvotes_count, :integer, default: 0
  end
end
