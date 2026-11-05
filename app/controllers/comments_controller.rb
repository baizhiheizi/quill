# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :load_article, only: :index
  before_action :authenticate_user!, only: :create

  def index
    comments =
      if @article.present?
        @article.comments
      else
        Comment.none
      end

    @order_by = params[:order_by] || "upvotes"
    comments =
      case @order_by
      when "upvotes"
        comments.order(upvotes_count: :desc, downvotes_count: :asc, created_at: :desc)
      when "asc"
        comments.order(created_at: :asc)
      else
        comments.order(created_at: :desc)
      end

    @pagy, @comments = pagy comments.without_deleted.includes(*COMMENTS_INDEX_PRELOADS)

    # The `_actions` partial asks "has the viewer voted on this comment?" per
    # row. Prime the page's answer sets here so the partial reads them instead
    # of firing two SELECTs per comment; the sets are scoped to this page's
    # ids because a viewer's comment votes span every article they ever read.
    page_ids = @comments.map(&:id)
    @preloaded_upvoted_comment_ids = ids_for(:upvote_comment, target_ids: page_ids)
    @preloaded_downvoted_comment_ids = ids_for(:downvote_comment, target_ids: page_ids)
  end

  # Everything one comments-list row touches: the author's avatar chain, the
  # commentable (the `_actions` reply gate calls `commentable.authorized?` per
  # row — with the commentable preloaded all rows share one Article instance,
  # so the memoized answer costs one SELECT for the whole page), the comment's
  # own rich text, and the quoted comment with its author, its commentable and
  # its rich text.
  #
  # `User::AVATAR_PRELOADS` is the model constant every avatar surface shares
  # (see `ArticlesController#preloaded_random_readers`).
  COMMENTS_INDEX_PRELOADS = [
    { author: User::AVATAR_PRELOADS },
    { commentable: :author },
    :rich_text_content,
    {
      quote_comment: [
        { author: User::AVATAR_PRELOADS },
        { commentable: :author },
        :rich_text_content
      ]
    }
  ].freeze

  def new
    if params[:quote_comment_id].present?
      @quote_comment = Comment.find_by id: params[:quote_comment_id]
      @commentable = @quote_comment&.commentable
    elsif params[:commentable_type] == "Article"
      @commentable = Article.find_by id: params[:commentable_id]
    end

    return head :not_found if @commentable.blank?

    authorize @commentable, :comment?
  end

  def create
    commentable = find_commentable
    return head :forbidden if commentable.blank?

    authorize commentable, :comment?

    @comment = current_user.comments.create(
      comment_params.except(:commentable_id, :commentable_type).merge(commentable:)
    )

    if @comment.persisted?
      PostHog.capture(
        distinct_id: current_user.posthog_distinct_id,
        event: "comment_created",
        properties: {
          article_uuid: commentable.respond_to?(:uuid) ? commentable.uuid : nil,
          commentable_type: commentable.class.name
        }
      )
    end
  end

  private

  def find_commentable
    if params.dig(:comment, :quote_comment_id).present?
      quote_comment = Comment.find_by(id: params.dig(:comment, :quote_comment_id))
      commentable = quote_comment&.commentable
    elsif params.dig(:comment, :commentable_type) == "Article"
      commentable = Article.without_drafted.find_by(id: params.dig(:comment, :commentable_id))
    end

    return if commentable.blank?
    return unless commentable.is_a?(Article)
    return unless commentable.published? || commentable.authorized?(current_user)

    commentable
  end

  def load_article
    article = Article.without_drafted.find_by uuid: params[:article_uuid]
    @article = article if article&.published? || article&.authorized?(current_user)
  end

  def comment_params
    params.require(:comment).permit(:commentable_id, :commentable_type, :content, :quote_comment_id)
  end
end
