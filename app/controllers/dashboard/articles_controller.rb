# frozen_string_literal: true

class Dashboard::ArticlesController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'published'

    articles =
      case @tab
      when 'drafted'
        current_user.articles.drafted
      when 'hidden'
        current_user.articles.hidden
      when 'blocked'
        current_user.articles.blocked
      else
        current_user.articles.published
      end

    @pagy, @articles = pagy articles.order(updated_at: :desc)
  end

  def hide
  end

  def publish
  end
end
