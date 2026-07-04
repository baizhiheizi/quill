# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  # Default section per controller for the new grouped rail/tabbar
  # (`shared/_dashboard_rail`, `shared/_dashboard_tabbar`) to highlight the
  # user's current location (spec FR-005). A handful of controllers serve
  # more than one section depending on request params (e.g. `ArticlesController`
  # renders both "my drafts" (Write) and "my bought articles" (Read) behind the
  # same `tab` param) — those override `@active_section` in their own actions
  # instead of relying on this default.
  SECTION_BY_CONTROLLER = {
    "Dashboard::HomeController" => :overview,
    "Dashboard::ArticlesController" => :write,
    "Dashboard::PublishedArticlesController" => :write,
    "Dashboard::DeletedArticlesController" => :write,
    "Dashboard::CollectionsController" => :write,
    "Dashboard::HiddenCollectionsController" => :write,
    "Dashboard::ListedCollectionsController" => :write,
    "Dashboard::CommentsController" => :read,
    "Dashboard::SubscriptionsController" => :read,
    "Dashboard::SubscribeArticlesController" => :read,
    "Dashboard::SubscribeTagsController" => :read,
    "Dashboard::SubscribeUsersController" => :read,
    "Dashboard::SubscribeByUsersController" => :read,
    "Dashboard::OrdersController" => :finances,
    "Dashboard::PaymentsController" => :finances,
    "Dashboard::TransfersController" => :finances,
    "Dashboard::NotificationsController" => :notifications,
    "Dashboard::ReadNotificationsController" => :notifications,
    "Dashboard::DeletedNotificationsController" => :notifications,
    "Dashboard::NotificationSettingsController" => :notifications,
    "Dashboard::ProfileSettingsController" => :account,
    "Dashboard::BlockUsersController" => :account,
    "Dashboard::AccessTokensController" => :account
  }.freeze

  before_action :authenticate_user!
  before_action :set_default_active_section

  private

  def authenticate_user!
    redirect_to login_path(return_to: URI.encode_www_form_component("/dashboard")) if current_user.blank?
  end

  def set_default_active_section
    @active_section ||= SECTION_BY_CONTROLLER[self.class.name]
  end
end
