# frozen_string_literal: true

module Resolvers
  class AdminArticleConnectionResolver < AdminBaseResolver
    argument :author_mixin_uuid, ID, required: false
    argument :query, String, required: false
    argument :state, String, required: false
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(**params)
      articles =
        if params[:author_mixin_uuid].present?
          User.find_by(mixin_uuid: params[:author_mixin_uuid]).articles
        else
          Article.all
        end

      articles =
        case params[:state]
        when 'published'
          articles.published
        when 'hidden'
          articles.hidden
        when 'blocked'
          articles.blocked
        else
          articles
        end

      q = params[:query].to_s.strip
      q_ransack = { title_cont: q, intro_cont: q, content_cont: q, author_name_cont: q }
      articles = articles.ransack(q_ransack.merge(m: 'or')).result

      articles.order(created_at: :desc)
    end
  end
end
