# frozen_string_literal: true

module Mutations
  class UpdateArticleMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true
    argument :title, String, required: false
    argument :intro, String, required: false
    argument :content, String, required: false
    argument :price, Float, required: false
    argument :tag_names, [String], required: false

    field :error, String, null: true

    def resolve(params)
      article = current_user.articles.find_by(uuid: params[:uuid])
      return if article.blank?

      params.delete(:price) if article.free? || (!article.free? && params[:price].zero?)

      article.assign_attributes(
        ActionController::Parameters.new(params).permit(
          :title,
          :intro,
          :content,
          :price
        )
      )

      if article.save
        CreateTag.call(article, params[:tag_names] || [])
        { error: nil }
      else
        { error: article.errors.full_messages.join(';').presence }
      end
    end
  end
end
