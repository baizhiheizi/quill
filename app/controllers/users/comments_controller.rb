# frozen_string_literal: true

module Users
  class CommentsController < Users::BaseController
    def index
      # Eager-load the polymorphic `commentable: :author` chain consumed by
      # `users/comments/_comment.html.erb` (`comment.commentable.title`,
      # `comment.commentable.author`). Without this, each row fires 2
      # SELECTs (polymorphic commentable + its author), so a 50-row page
      # runs ~101 SELECTs. Both `Comment` and `Article` carry
      # `belongs_to :author`, so the nested key resolves for either
      # commentable type.
      @pagy, @comments = pagy(:countless, @user.comments
        .includes(:commentable, :author, commentable: :author)
        .order(created_at: :desc))
    end
  end
end
