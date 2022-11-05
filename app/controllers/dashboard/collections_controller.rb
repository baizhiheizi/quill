# frozen_string_literal: true

class Dashboard::CollectionsController < Dashboard::BaseController
  before_action :authenticate_validated_user!, only: %i[new create]
  before_action :load_collection, only: %i[show edit update destroy]

  def index
    @collections = current_user.collections.order(updated_at: :desc)
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
      redirect_to dashboard_authorings_path(tab: :collections), success: t('success_updated')
    else
      render :new, status: :bad_request
    end
  end

  def update
    @collection.assign_attributes collection_params

    unless @collection.drafted?
      Trident
        .api
        .update_collection(
          @collection.uuid,
          description: collection_params[:description],
          external_url: collection_params[:external_url],
          icon_url: @collection.cover.changed? ? @collection.cover_url : ''
        )
    end

    if @collection.save
      redirect_to dashboard_authorings_path(tab: :collections), success: t('success_updated')
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    return unless @collection.may_destroy?

    @collection.destroy
    redirect_to dashboard_authorings_path(tab: :collections), success: t('success_deleted')
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

  def authenticate_validated_user!
    return if current_user&.validated?

    redirect_back fallback_location: root_path
  end
end
