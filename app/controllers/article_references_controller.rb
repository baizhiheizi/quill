# frozen_string_literal: true

class ArticleReferencesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Access listing, not discovery: the picker enumerates the articles the
    # viewer can already reach (bought / own / free), so the block rule does
    # not apply — same reason `ArticleSearchService` skips it for
    # `filter: "bought"`. `current_user.available_articles` is exactly the
    # bought ∪ own ∪ free set this action used to union in Ruby, deduped in
    # SQL instead.
    @articles =
      ArticleVisibility
      .for(current_user, base: current_user.available_articles, hide_blocked_authors: false)
      .searching(params[:query])
  end
end
