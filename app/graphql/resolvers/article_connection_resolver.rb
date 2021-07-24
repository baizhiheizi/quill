# frozen_string_literal: true

module Resolvers
  class ArticleConnectionResolver < BaseResolver
    argument :query, String, required: false
    argument :tag_id, ID, required: false
    argument :after, String, required: false
    argument :filter, String, required: true
    argument :time_range, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      articles = Tag.find_by(id: params[:tag_id])&.articles if params[:tag_id].present?
      articles ||= Article.all

      q = params[:query].to_s.strip
      q_ransack = { title_cont: q, intro_cont: q, author_name_cont: q, tags_name_cont: q }
      articles = articles.ransack(q_ransack.merge(m: 'or')).result.only_published

      articles =
        case params[:time_range]
        when 'week'
          articles.where(published_at: (Time.current - 1.week)...)
        when 'month'
          articles.where(published_at: (Time.current - 1.month)...)
        when 'year'
          articles.where(published_at: (Time.current - 1.year)...)
        else
          articles
        end

      case params[:filter]
      when 'default'
        articles.order_by_popularity
      when 'lately'
        articles.order(published_at: :desc)
      when 'revenue'
        articles.order_by_revenue_usd
      when 'subscribed'
        articles.where(author_id: current_user&.authoring_subscribe_user_ids).order(published_at: :desc)
      end
    end
  end
end
