class AddCounterCacheForTags < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :tags_count, :integer, default: 0
    add_column :tags, :articles_count, :integer, default: 0
  end
end
