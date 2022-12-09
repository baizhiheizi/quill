# frozen_string_literal: true

class Collections::BaseController < ApplicationController
  before_action :load_collection

  private

  def load_collection
    @collection = Collection.find_by uuid: params[:collection_uuid]
    redirect_to root_path unless @collection&.listed?
  end
end
