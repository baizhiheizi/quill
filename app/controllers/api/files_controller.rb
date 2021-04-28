# frozen_string_literal: true

class API::FilesController < API::BaseController
  def show
    snapshot = ArticleSnapshot.find_by file_hash: params[:hash]

    render_not_found if snapshot.blank?

    render plain: snapshot.encrypted_file_content
  end
end
