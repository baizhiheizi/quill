# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  articles_count    :integer          default(0)
#  locale            :string
#  name              :string
#  subscribers_count :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Tag < ApplicationRecord
  has_many :taggings, dependent: :nullify
  has_many :articles, through: :taggings, dependent: :nullify

  validates :name, uniqueness: true, allow_blank: false
  before_validation :setup_locale

  scope :recommended, -> { order(articles_count: :desc, created_at: :desc) }
  scope :hot, lambda {
    joins(:articles)
      .where(
        articles: {
          state: :published,
          created_at: (3.months.ago)...
        }
      ).group(:id)
      .select(
        <<~SQL.squish
          tags.*,
          COUNT(articles.id) AS lately_article_count
        SQL
      ).order(lately_article_count: :desc, created_at: :desc)
  }

  def update_locale
    update locale: detect_locale
  end

  def detect_locale
    CLD.detect_language(name)[:code]
  end

  private

  def setup_locale
    assign_attributes(
      locale: detect_locale
    )
  end
end
