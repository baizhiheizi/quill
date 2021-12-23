# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  articles_count    :integer          default(0)
#  name              :string
#  subscribers_count :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Tag < ApplicationRecord
  COLORS = %w[gray magenta red orange gold lime green cyan blue purple].freeze

  has_many :taggings, dependent: :nullify
  has_many :articles, through: :taggings, dependent: :nullify

  validates :name, uniqueness: true, allow_blank: false

  scope :recommended, -> { order(articles_count: :desc, created_at: :desc) }
  scope :hot, lambda {
    joins(:articles)
      .where(articles: { created_at: (Time.current - 1.month)... })
      .group(:id)
      .select(
        <<~SQL.squish
          tags.*,
          COUNT(articles.id) AS lately_article_count
        SQL
      ).order(lately_article_count: :desc, created_at: :desc)
  }

  def color
    @color ||= COLORS[id % COLORS.size]
  end
end
