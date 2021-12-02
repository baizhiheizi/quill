# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: %i[edit update publish]
  before_action :load_article, only: %i[edit update publish]

  def index
    @articles = Article.only_published.order(created_at: :desc).first(20)
    respond_to do |format|
      format.html
      format.rss do
        render layout: false
      end
    end
  end

  def new
    @article = current_user.articles.new
  end

  def edit
  end

  def show
    @article = Article.only_published.find_by uuid: params[:uuid]
    if @article.blank?
      redirect_to root_path, alert: t('article_not_found')
    else
      @page_title = "#{@article.title} - #{@article.author.name}"
      @page_description = @article.intro
    end
  end

  def create
    article = current_user.articles.new article_params

    if article.save
      redirect_to edit_article_path(article.uuid)
    else
      render :new
    end
  end

  def update
    @article.update article_params
  end

  def publish
  end

  private

  def article_params
    params.require(:article).permit(:title, :rich_content)
  end

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
