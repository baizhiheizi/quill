# frozen_string_literal: true

class API::FilesController < API::BaseController
  def show
    snapshot = ArticleSnapshot.find_by file_hash: params[:hash]

    if snapshot.blank?
      render_not_found
    else
      render plain: snapshot.encrypted_file_content
    end
  end
end
