# frozen_string_literal: true

class Grover::CollectionsController < Grover::BaseController
  def cover
    @collection = Collection.find params[:collection_id]
    @width = 640
    @height = 640
  end
end
