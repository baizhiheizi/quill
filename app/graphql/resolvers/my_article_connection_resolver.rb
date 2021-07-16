# frozen_string_literal: true

module Resolvers
  class MyArticleConnectionResolver < MyBaseResolver
    argument :type, String, required: true
    argument :query, String, required: false
    argument :state, String, required: false
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      articles =
        case params[:type]
        when 'author'
          if params[:state].present?
            current_user.articles.where(state: params[:state]).order(created_at: :desc)
          else
            current_user.articles.order(created_at: :desc)
          end
        when 'reader'
          current_user.bought_articles.order(published_at: :desc)
        when 'available'
          current_user.available_articles
        end

      q = params[:query].to_s.strip
      q_ransack = { title_cont: q, intro_cont: q, author_name_cont: q, tags_name_cont: q }
      articles.ransack(q_ransack.merge(m: 'or')).result
    end
  end
end
