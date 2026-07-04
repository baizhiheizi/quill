# frozen_string_literal: true

class Dashboard::HomeController < Dashboard::BaseController
  RECENT_LIMIT = 3

  # Composed entirely from already-existing `Users::Statable` aggregate
  # methods (counter caches / small indexed sums, already used to power the
  # rail's notification badge and the Write/Read workspaces' earnings tabs)
  # plus two small `.limit(3)` recency queries following the exact
  # `.includes(...)` eager-loading shape already used by
  # `Dashboard::ArticlesController#index` — no new queries, jobs, or caching
  # layer (specs/005-dashboard-ux-redesign data-model.md "Dashboard Overview").
  def index
    @active_section = :overview
    @is_author = current_user.articles_count > 0
    @unread_notifications_count = current_user.unread_notifications_count
    @author_revenue_total_usd = current_user.author_revenue_total_usd if @is_author
    @reader_revenue_total_usd = current_user.reader_revenue_total_usd
    @recent_articles = current_user.articles.published
      .order(updated_at: :desc)
      .limit(RECENT_LIMIT)
      .includes(:currency, :tags, cover_attachment: :blob)
    @recent_reads = current_user.bought_articles
      .order(created_at: :desc)
      .limit(RECENT_LIMIT)
      .includes(:author, :currency)
  end

  def write
    @active_section = :write
    @tab = params[:tab] || "drafted"
  end

  def read
    @active_section = :read
    @tab = params[:tab] || "bought"
  end

  def finances
    @active_section = :finances
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
