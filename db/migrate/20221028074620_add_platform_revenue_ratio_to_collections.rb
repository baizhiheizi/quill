class AddPlatformRevenueRatioToCollections < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :platform_revenue_ratio, :float, default: 0.1
  end
end
