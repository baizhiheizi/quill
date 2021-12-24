# frozen_string_literal: true

module Users
  class CommentsController < Users::BaseController
    def index
      @pagy, @comments = pagy_countless @user.comments.order(created_at: :desc)
    end
  end
end
