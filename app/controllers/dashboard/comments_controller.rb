# frozen_string_literal: true

class Dashboard::CommentsController < Dashboard::BaseController
  def index
    @pagy, @comments = pagy current_user.comments.includes(:commentable)
  end
end
