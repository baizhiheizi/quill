# frozen_string_literal: true

class Dashboard::CommentsController < Dashboard::BaseController
  def index
    @comments = current_user.comments.includes(:commentable)
  end
end
