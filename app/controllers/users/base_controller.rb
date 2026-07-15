# frozen_string_literal: true

class Users::BaseController < ApplicationController
  before_action :load_user!, :set_page_meta

  private

  def load_user!
    @user = User.find_by(uid: params[:user_uid])
    render_not_found_page if @user.blank?
  end

  def set_page_meta
    @page_title = @user.name
    @page_description = @user.bio
    @page_image = @user.avatar
  end

  # Set of `User#id`s that `current_user` is subscribed to, in a single
  # SELECT. Mirrors `Dashboard::BaseController#preloaded_subscribe_user_ids`
  # — the `subscribe_users/_subscribe_button.html.erb` partial (rendered
  # from `users/subscribe_users/_user.html.erb` and the dashboard/user
  # card) consults it and would otherwise call
  # `current_user.subscribe_user?(user)` once per row. Returns an empty
  # Set for guests — unlike the dashboard, the Users namespace does not
  # `authenticate_user!`, so this endpoint is reachable from the public
  # profile page. The partial falls through to the live helper for
  # guests and stays correct.
  def preloaded_subscribe_user_ids
    return @preloaded_subscribe_user_ids if defined?(@preloaded_subscribe_user_ids)
    @preloaded_subscribe_user_ids =
      if current_user
        current_user.subscribe_user_actions.pluck(:target_id).to_set
      else
        Set.new
      end
  end

  # Same avatar-ActiveStorage chain as
  # `UserFieldPreloads#user_field_preloads`. Kept inline in the Users base
  # (rather than shared across both bases) because the two paths currently
  # use the same shape — if a third caller appears, lift it to a shared
  # module instead of copy-pasting again.
  def users_user_field_preloads
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
