# frozen_string_literal: true

class CollectionsController < ApplicationController
  def index
    @collections = Collection.listed.order(updated: :desc)
  end

  def show
    @collection = Collection.listed.find_by uuid: params[:uuid]
    if @collection.blank?
      redirect_back fallback_location: root_path
    else
      impressionist @collection

      @page_title = "#{@collection.name} - #{@collection.author.name}"
      @page_description = @collection.description
      @page_image = @collection.cover_url
    end
  end

  def share
    @collection = Collection.listed.find_by uuid: params[:collection_uuid]
    impressionist @collection, 'share'
  end
end
