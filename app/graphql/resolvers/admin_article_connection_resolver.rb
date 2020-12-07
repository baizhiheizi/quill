# frozen_string_literal: true

module Resolvers
  class AdminArticleConnectionResolver < AdminBaseResolver
    argument :query, String, required: false
    argument :state, String, required: false
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      articles =
        case params[:state]
        when 'published'
          Article.published
        when 'hidden'
          Article.hidden
        when 'blocked'
          Article.blocked
        else
          Article.all
        end

      q = params[:query].to_s.strip
      q_ransack = { title_cont: q, intro_cont: q, content_cont: q, author_name_cont: q }
      articles = articles.ransack(q_ransack.merge(m: 'or')).result

      articles.order(created_at: :desc)
    end
  end
end
