# frozen_string_literal: true

class Articles::ListComponent < ApplicationComponent
  def initialize(articles: [], pagy: nil, pagy_id: 'articles_pagination')
    super

    @articles = articles
    @pagy = pagy
    @pagy_id = pagy_id
  end
end
