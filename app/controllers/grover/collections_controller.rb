# frozen_string_literal: true

class Grover::CollectionsController < Grover::BaseController
  def cover
    @collection = Collection.find params[:collection_id]
  end
end
