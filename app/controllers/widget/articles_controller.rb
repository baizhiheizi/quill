# frozen_string_literal: true

class Widget::ArticlesController < Widget::BaseController
  def index
    @query = params[:query]&.split(',')&.map(&:strip) || []
    q_ransack = { title_i_cont_any: @query, intro_i_cont_any: @query, tags_name_i_cont_any: @query }
    @pagy, @articles =
      pagy(
        Article
        .only_published
        .includes(:author, :tags, :currency)
        .ransack(q_ransack.merge(m: 'or'))
        .result
        .order_by_popularity
      )
  end
end
