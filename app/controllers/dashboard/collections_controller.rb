# frozen_string_literal: true

class Dashboard::CollectionsController < Dashboard::BaseController
  before_action :load_collection, only: %i[show edit update destroy]

  def index
    # Eager-load `:currency` (used for `price_tag`, `price_usd`, `currency.icon_url` in the
    # partial) and the ActiveStorage `cover_attachment → :blob` chain (used for
    # `collection.cover.attached?` + `image_tag collection.cover`). Without these includes,
    # each row triggers ~3 SELECTs (currency + attachment + blob) — for an author with N
    # collections on /dashboard/collections, that is ~3N queries per index page load.
    @collections = current_user.collections.includes(:currency, cover_attachment: :blob).order(updated_at: :desc)
  end

  def show
  end

  def new
    @collection = current_user.collections.new
  end

  def edit
    @collection = current_user.collections.find params[:id]
  end

  def create
    @collection = current_user.collections.new collection_params

    if @collection.save
      redirect_to dashboard_write_path(tab: :collections), success: t("success_updated")
    else
      render :new, status: :bad_request
    end
  end

  def update
    @collection.assign_attributes collection_params

    if @collection.save
      redirect_to dashboard_write_path(tab: :collections), success: t("success_updated")
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    return unless @collection.may_destroy?

    @collection.destroy
    redirect_to dashboard_write_path(tab: :collections), success: t("success_deleted")
  end

  private

  def load_collection
    @collection = current_user.collections.find params[:id]
  end

  def collection_params
    params
      .require(:collection)
      .permit(:name, :symbol, :description, :asset_id, :price, :revenue_ratio)
  end
end
