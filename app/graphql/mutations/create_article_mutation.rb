# frozen_string_literal: true

module Mutations
  class CreateArticleMutation < Mutations::BaseMutation
    argument :title, String, required: true
    argument :intro, String, required: true
    argument :content, String, required: true
    argument :price, Float, required: true
    argument :state, String, required: true
    argument :tag_names, [String], required: false

    field :error, String, null: true

    def resolve(**params)
      article = current_user.articles.new(
        title: params[:title],
        intro: params[:intro],
        content: params[:content],
        price: params[:price],
        state: params[:state]
      )

      if article.save
        CreateTag.call(article, params[:tag_names] || [])
        { error: nil }
      else
        {
          error: article.errors.full_messages.join(';').presence
        }
      end
    end
  end
end
