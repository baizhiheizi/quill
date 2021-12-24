# frozen_string_literal: true

module Users
  class ArticlesController < Users::BaseController
    def index
      @tab = params[:tab] || 'published'
      articles =
        case @tab
        when 'published'
          @user.articles.published
        when 'bought'
          @user.bought_articles
        end

      @pagy, @articles = pagy_countless articles.order(published_at: :desc)
    end
  end
end
