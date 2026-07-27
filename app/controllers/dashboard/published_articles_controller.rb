# frozen_string_literal: true

class Dashboard::PublishedArticlesController < Dashboard::BaseController
  before_action :load_article

  def new
    @readiness_errors = publish_readiness_errors
  end

  def update
    if @article.published_at.present?
      @article.publish! if @article.may_publish?
    elsif @article.may_publish?
      if @article.publish!
        PostHog.capture(
          distinct_id: current_user.posthog_distinct_id,
          event: "article_published",
          properties: {
            article_uuid: @article.uuid,
            is_free: @article.free?,
            has_collection: @article.collection_id.present?
          }
        )
        redirect_to @article, notice: t("success_published_article")
      end
    end
  end

  def destroy
    @article.hide! if @article.may_hide?
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
    authorize @article, :update? if @article.present?
  end

  def publish_readiness_errors
    errors = []
    errors << I18n.t("articles.title_is_required") if @article.title.blank?
    errors << I18n.t("articles.intro_is_required") if @article.intro.blank?
    errors << I18n.t("articles.content_is_required") if @article.content.blank?

    @article.valid?
    errors.concat(@article.errors.full_messages)
    errors.uniq
  end
end
