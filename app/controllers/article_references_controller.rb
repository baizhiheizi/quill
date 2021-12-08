# frozen_string_literal: true

class ArticleReferencesController < ApplicationController
  before_action :authenticate_user!

  def index
    q = params[:query].to_s.strip
    q_ransack = { title_cont: q, intro_cont: q, author_name_cont: q, tags_name_cont: q, m: 'or' }

    @articles =
      if q.blank?
        current_user.available_articles
      else
        r1 = current_user.bought_articles.only_published.ransack(q_ransack).result
        r2 = current_user.articles.only_published.ransack(q_ransack).result
        r3 = Article.only_free.only_published.ransack(q_ransack).result
        (r1 + r2 + r3).uniq
      end
  end
end
