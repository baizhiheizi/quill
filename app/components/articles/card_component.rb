# frozen_string_literal: true

class Articles::CardComponent < ApplicationComponent
  with_collection_parameter :article

  def initialize(article:)
    super

    @article = article
  end
end
