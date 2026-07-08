# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
# Database name: primary
#
#  id                :bigint           not null, primary key
#  articles_count    :integer          default(0)
#  locale            :string
#  name              :string
#  subscribers_count :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_tags_on_name_trgm  (name) USING gin
#

class Tag < ApplicationRecord
  has_many :taggings, dependent: :nullify
  has_many :articles, through: :taggings, dependent: :nullify

  validates :name, uniqueness: true, allow_blank: false
  before_validation :setup_locale

  scope :recommended, -> { order(articles_count: :desc, created_at: :desc) }
  # `hot` filters to tags that have published articles in the last 3 months,
  # ordered by how many they have. The previous shape aliased
  # `COUNT(articles.id) AS lately_article_count` and used it for ordering;
  # that alias broke `Tag.hot.count` (PG syntax error: ActiveRecord built
  # `SELECT COUNT(tags.*, COUNT(articles.id) AS ...)`). Nothing reads the
  # alias outside this scope, so we order directly via `Arel.sql` and drop
  # the `select` so `count` works again.
  scope :hot, lambda {
    joins(:articles)
      .where(
        articles: {
          state: :published,
          created_at: (3.months.ago)...
        }
      ).group(:id)
      .order(Arel.sql("COUNT(articles.id) DESC, tags.created_at DESC"))
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
