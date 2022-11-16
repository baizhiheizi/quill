# frozen_string_literal: true

class Dashboard::ImportedArticlesController < Dashboard::BaseController
  def new
  end

  def create
    current_user.import_articles_from_mirror_async

    render_flash :success, t('importing_tips')
  end
end
