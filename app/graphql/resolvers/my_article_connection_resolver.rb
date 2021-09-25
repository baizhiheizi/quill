# frozen_string_literal: true

module Resolvers
  class MyArticleConnectionResolver < MyBaseResolver
    argument :type, String, required: true
    argument :query, String, required: false
    argument :state, String, required: false
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      q = params[:query].to_s.strip
      q_ransack = { title_cont: q, intro_cont: q, author_name_cont: q, tags_name_cont: q, m: 'or' }

      case params[:type]
      when 'author'
        if params[:state].present?
          current_user
            .articles
            .where(state: params[:state])
            .order(created_at: :desc)
            .ransack(q_ransack).result
        else
          current_user
            .articles
            .order(created_at: :desc)
            .ransack(q_ransack).result
        end
      when 'reader'
        current_user
          .bought_articles
          .order(published_at: :desc)
          .ransack(q_ransack).result
      when 'available'
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
  end
end
