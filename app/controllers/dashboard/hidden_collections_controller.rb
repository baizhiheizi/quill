# frozen_string_literal: true

class Dashboard::HiddenCollectionsController < Dashboard::BaseController
  before_action :load_collection

  def new
  end

  def update
    @collection.hide! if @collection.may_hide?

    redirect_to dashboard_authorings_path(tab: :collections)
  end

  private

  def load_collection
    @collection = current_user.collections.find params[:id]
  end
end
