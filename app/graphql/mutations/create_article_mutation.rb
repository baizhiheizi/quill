# frozen_string_literal: true

module Mutations
  class CreateArticleMutation < Mutations::BaseMutation
    input_object_class Types::ArticleInputType

    type Boolean

    def resolve(**params)
      article = current_user.articles.new(
        title: params[:title],
        intro: params[:intro],
        content: params[:content],
        price: params[:price],
        state: params[:state],
        asset_id: params[:asset_id]
      )

      if params[:article_references].present?
        article_references = params[:article_references].uniq(&:reference_id)
        references_revenue_ratio = article_references.sum(&:revenue_ratio)&.to_f

        article_references.each do |reference|
          _ref = current_user.bought_articles.find_by(id: reference.reference_id)
          _ref ||= current_user.available_articles.find_by(uuid: reference.reference_id)
          next if _ref.blank?

          article.article_references.new(
            reference: _ref,
            revenue_ratio: reference.revenue_ratio
          )
        end

        article.assign_attributes(
          author_revenue_ratio: Article::AUTHOR_REVENUE_RATIO_DEFAULT - references_revenue_ratio,
          references_revenue_ratio: references_revenue_ratio
        )
      end

      article.save!
      CreateTag.call(article, params[:tag_names] || [])

      article.id.present?
    end
  end
end
