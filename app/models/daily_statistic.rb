# frozen_string_literal: true

# == Schema Information
#
# Table name: statistics
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  datetime   :datetime
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DailyStatistic < Statistic
  store_accessor :data, %i[
    new_users_count
    paid_users_count
    new_payments_count
    new_payers_count
    new_articles_count
    author_revenue_total_in_usd
    reader_revenue_total_in_usd
  ]

  before_validation :setup_attributes, on: :create

  default_scope -> { order(datetime: :asc) }

  def self.generate(date: Time.current.yesterday)
    find_or_create_by(
      datetime: date
    )
  end

  def regenerate
    update data_attributes(datetime)
  end

  def data_attributes(date)
    {
      new_users_count: User.where(created_at: date.beginning_of_day...date.end_of_day).count,
      paid_users_count: Order.completed.where(order_type: %i[buy_article reward_article buy_collection], created_at: ...date.end_of_day).pluck(:buyer_id).uniq.count,
      new_payments_count: Order.completed.where(order_type: %i[buy_article reward_article buy_collection], created_at: date.beginning_of_day...date.end_of_day).count,
      new_payers_count: Order.completed.where(order_type: %i[buy_article reward_article buy_collection], created_at: date.beginning_of_day...date.end_of_day).pluck(:buyer_id).uniq.count,
      new_articles_count: Article.where(published_at: date.beginning_of_day...date.end_of_day).count,
      author_revenue_total_in_usd: Transfer.joins(:currency).where(transfer_type: :author_revenue, created_at: date.beginning_of_day...date.end_of_day).sum('amount * currencies.price_usd').to_f.round(4),
      reader_revenue_total_in_usd: Transfer.joins(:currency).where(transfer_type: :reader_revenue, created_at: date.beginning_of_day...date.end_of_day).sum('amount * currencies.price_usd').to_f.round(4)
    }
  end

  def setup_attributes
    assign_attributes data: data_attributes(datetime)
  end
end
