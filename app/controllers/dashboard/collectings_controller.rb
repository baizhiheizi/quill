# frozen_string_literal: true

class Dashboard::CollectingsController < Dashboard::BaseController
  before_action :load_collection

  def create
    uuid = params.require(:collecting).permit(:nft_collection_id)['nft_collection_id']
    nft_collection = NftCollection.find_or_create_by!(uuid:)
    @collection.collectings.find_or_create_by! nft_collection:
  rescue ActiveRecord::RecordInvalid => e
    render_flash :warning, e.inspect
  end

  def destroy
    @collection.collectings.find(params[:id]).destroy
  end

  private

  def load_collection
    @collection = Collection.find params[:collection_id]
  end
end
