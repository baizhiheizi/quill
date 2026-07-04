# frozen_string_literal: true

class Dashboard::HomeController < Dashboard::BaseController
  def index
    redirect_to dashboard_read_path
  end

  def write
    @active_section = :write
    @tab = params[:tab] || "drafted"
  end

  def read
    @active_section = :read
    @tab = params[:tab] || "bought"
  end

  def account
    @active_section = :account
    @tab = params[:tab] || "profile"
  end

  # Legacy paths kept resolving per FR-030/SC-008 — old bookmarks/links
  # redirect straight to their new canonical equivalent, tab params preserved.
  def redirect_readings
    redirect_to dashboard_read_path(tab: params[:tab])
  end

  def redirect_authorings
    redirect_to dashboard_write_path(tab: params[:tab])
  end

  def redirect_settings
    redirect_to dashboard_account_path(tab: params[:tab])
  end

  def redirect_stats
    redirect_to dashboard_root_path
  end
end
