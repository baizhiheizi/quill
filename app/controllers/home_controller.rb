# frozen_string_literal: true

class HomeController < ApplicationController
  layout 'homepage', only: :index

  def index
    redirect_to articles_path if current_user.present? || browser.device.mobile?
  end

  def selected_articles
    @articles = ArticleSearchService.call(filter: 'revenue', time_range: 'month', locale: current_locale).limit(6)
  end

  def hot_tags
    hot_tags =
      Rails.cache.fetch "#{current_locale}_hot_tags", expires_in: 5.minutes do
        Tag
          .hot
          .where(locale: current_locale.to_s.split('-').first)
          .limit(50)
      end

    @hot_tags = hot_tags.sample(5)
  end

  def active_authors
    @users =
      User
      .active
      .where.not(id: current_user&.block_user_ids)
      .where.not(id: current_user&.id)
      .where(locale: current_locale)
      .limit(20)
      .sample(5)
  end

  def more
    redirect_to root_path unless browser.device.mobile?
  end
end
