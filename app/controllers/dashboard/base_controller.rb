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

  # Eager-load chain for the per-row User partials on the dashboard
  # (currently `dashboard/block_users/_user.html.erb` and
  # `dashboard/subscribe_users/_user.html.erb`, both of which render
  # `shared/_avatar` with `thumb: true`).
  #
  # Without these `includes` each row fires:
  #   - 1 SELECT for the `authorization` row (read in
  #     `User#avatar_image_thumb`'s OAuth-fallback branch)
  #   - 1 SELECT for `avatar_attachment`
  #   - 1 SELECT for the attachment `blob`
  #   - 1 SELECT for the `variant_records` (the `:thumb` variant)
  #   - 1 SELECT for the variant's `image_attachment` blob
  #
  # That's ~5 SELECTs per row. With a 24-row pagy page that's ~120 SELECTs
  # before the view even hits the action_store check below.
  #
  # Same shape as `Admin::BaseController#admin_user_field_preloads`. Lives
  # here too so dashboard endpoints don't have to inline the chain (and
  # drift from the admin version over time).
  def dashboard_user_field_preloads
    [
      :authorization,
      {
        avatar_attachment: {
          blob: {
            variant_records: { image_attachment: :blob },
            preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } }
          }
        }
      }
    ]
  end
end
