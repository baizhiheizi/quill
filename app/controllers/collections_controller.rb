# frozen_string_literal: true

class CollectionsController < ApplicationController
  def index
    @collections = Collection.listed.order(updated: :desc)
  end

  def show
    @collection = Collection.listed.find_by uuid: params[:uuid]
    impressionist @collection

    @articles = @collection.articles.published

    @page_title = "#{@collection.name} - #{@collection.author.name}"
    @page_description = @collection.description
    @page_image = @collection.cover_url
  end

  def share
    @collection = Collection.listed.find_by uuid: params[:collection_uuid]
    impressionist @collection, 'share'
  end
end
