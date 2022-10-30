# frozen_string_literal: true

class Grover::CollectiblesController < Grover::BaseController
  def show
    @collection = Collection.find params[:collection_id]
    @identifier = params[:identifier]
    @width = 640
    @height = 640
  end
end
