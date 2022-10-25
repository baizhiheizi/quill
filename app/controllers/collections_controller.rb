# frozen_string_literal: true

class CollectionsController < ApplicationController
  def index
    @collections = Collection.listed.order(updated: :desc)
  end

  def show
    @collection = Collection.listed.find_by uuid: params[:uuid]
  end
end
