class AddRevenueRatiosToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :platform_revenue_ratio, :float, default: 0.1
    add_column :articles, :readers_revenue_ratio, :float, default: 0.4
    add_column :articles, :author_revenue_ratio, :float, default: 0.5
    add_column :articles, :references_revenue_ratio, :float, default: 0.0
  end
end
