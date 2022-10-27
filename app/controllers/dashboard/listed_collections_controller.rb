# frozen_string_literal: true

class Dashboard::ListedCollectionsController < Dashboard::BaseController
  before_action :load_collection

  def new
  end

  def update
    @collection.list_on_trident! unless @collection.listed_on_trident?
    @collection.list! if @collection.may_list?

    redirect_to dashboard_authorings_path(tab: :collections)
  end

  private

  def load_collection
    @collection = current_user.collections.find params[:id]
  end
end
