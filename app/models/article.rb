# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                                  :bigint           not null, primary key
#  content                             :text
#  intro                               :string
#  orders_count                        :integer          default(0), not null
#  price                               :decimal(, )      not null
#  revenue                             :decimal(, )      default(0.0)
#  title                               :string
#  uuid                                :uuid
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  asset_id(asset_id in Mixin Network) :uuid
#  author_id                           :bigint
#
# Indexes
#
#  index_articles_on_author_id  (author_id)
#  index_articles_on_uuid       (uuid) UNIQUE
#
class Article < ApplicationRecord
  PRS_ASSET_ID = '3edb734c-6d6f-32ff-ab03-4eb43640c758'

  belongs_to :author, class_name: 'User', inverse_of: :articles

  has_many :orders, as: :item, dependent: :nullify
  has_many :readers, through: :orders, source: :payer
  has_many :comments, as: :commentable, dependent: :nullify

  validates :uuid, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 25 }
  validates :intro, presence: true, length: { maximum: 140 }
  validates :content, presence: true
  validates :price, numericality: { greater_than: 0.00000001 }

  before_validation :setup_attributes, on: :create

  def authorize?(user)
    return if user.blank?
    return true if author == user

    orders.find_by(payer: user).present?
  end

  def update_revenue
    update revenue: orders.sum(:total)
  end

  private

  def setup_attributes
    return unless new_record?

    assign_attributes(
      asset_id: PRS_ASSET_ID,
      price: price.round(8),
      uuid: SecureRandom.uuid
    )
  end
end
