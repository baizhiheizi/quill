# frozen_string_literal: true

class CollectionsController < ApplicationController
  def index
    @collections = Collection.listed.order(updated: :desc)
  end

  def show
    @collection = Collection.listed.find_by uuid: params[:uuid]
    @articles = @collection.articles.published
  end

  def share
    @collection = Collection.listed.find_by uuid: params[:collection_uuid]
  end
end