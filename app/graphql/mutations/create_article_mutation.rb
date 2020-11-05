# frozen_string_literal: true

module Mutations
  class CreateArticleMutation < Mutations::BaseMutation
    argument :title, String, required: true
    argument :intro, String, required: true
    argument :content, String, required: true
    argument :price, Float, required: true
    argument :state, String, required: true

    field :error, String, null: true

    def resolve(title:, intro:, content:, price:, state:)
      article = current_user.articles.create(
        title: title,
        intro: intro,
        content: content,
        price: price,
        state: state
      )

      { error: article.errors.full_messages.join(';').presence }
    end
  end
end
