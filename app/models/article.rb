# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                                  :bigint           not null, primary key
#  content                             :text
#  intro                               :string
#  price                               :decimal(, )      not null
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

  validates :uuid, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 25 }
  validates :intro, presence: true, length: { maximum: 140 }
  validates :content, presence: true
  validates :price, numbericality: { greater_than: 0.00000001 }

  before_validation :setup_attributes

  def setup_attributes
    self.asset_id = PRS_ASSET_ID
    self.price = price.round(8)
  end
end
