class AddFreeContentPercentToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :free_content_ratio, :float, default: 0.1
  end
end
