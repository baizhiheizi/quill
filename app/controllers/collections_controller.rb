# frozen_string_literal: true

class CollectionsController < ApplicationController
  def index
    @collections = Collection.listed.order(updated_at: :desc)
  end

  def show
    @collection = Collection.listed.find_by uuid: params[:uuid]
    if @collection.blank?
      render_not_found_page
    else
      impressionist @collection

      @page_title = "#{@collection.name} - #{@collection.author.name}"
      @page_description = @collection.description
      @page_image = @collection.cover_url
    end
  end

  def share
    @collection = Collection.listed.find_by uuid: params[:collection_uuid]
    return render_not_found_page if @collection.blank?

    impressionist @collection, "share"
  end
end
