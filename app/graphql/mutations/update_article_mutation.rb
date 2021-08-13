# frozen_string_literal: true

module Mutations
  class UpdateArticleMutation < Mutations::BaseMutation
    input_object_class Types::ArticleUpdateInputType

    type Types::ArticleType

    def resolve(params)
      article = current_user.articles.find_by(uuid: params[:uuid])
      return if article.blank?

      if article.drafted?
        article.assign_attributes(
          ActionController::Parameters.new(params).permit(
            :title,
            :intro,
            :content
          )
        )
      else
        params.delete(:price) if article.free? || (!article.free? && params[:price].zero?)
        article.assign_attributes(
          ActionController::Parameters.new(params).permit(
            :title,
            :intro,
            :content,
            :price
          )
        )
      end

      if article.save
        CreateTag.call(article, params[:tag_names] || [])
      end

      article.reload
    end
  end
end
