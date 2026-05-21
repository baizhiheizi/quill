# frozen_string_literal: true

class Dashboard::ListedCollectionsController < Dashboard::BaseController
  before_action :load_collection

  def new
  end

  def update
    if @collection.published?
      @collection.list! if @collection.may_list?
    else
      @collection.publish!
    end

    redirect_to dashboard_authorings_path(tab: :collections), success: t("success_updated")
  rescue StandardError => e
    redirect_to dashboard_authorings_path(tab: :collections), warning: e.inspect
  end

  private

  def load_collection
    @collection = current_user.collections.find params[:id]
  end
end
