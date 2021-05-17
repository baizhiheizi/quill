# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?
  Administrator.create name: 'admin', password: 'admin'
end

SwapOrder::SWAPABLE_ASSETS.each do |asset|
  Currency.find_or_create_by_asset_id asset
end
