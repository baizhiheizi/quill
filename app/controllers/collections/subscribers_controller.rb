# frozen_string_literal: true

class Collections::SubscribersController < Collections::BaseController
  # The subscriber list renders two partials that each fire per-row
  # queries without preloads:
  #
  #   - `shared/_avatar` reads `subscriber.avatar_image_thumb` and
  #     `_url`, which load `authorization`, `avatar_attachment`,
  #     `blob`, `variant_records`, and `preview_image_attachment`.
  #     Without preloads every subscriber fires ~5 SELECTs.
  #   - `subscribe_users/_subscribe_button` calls
  #     `current_user.subscribe_user?(user)` per row (action_store
  #     fires one SELECT per call) unless `@preloaded_subscribe_user_ids`
  #     is set in the controller.
  #
  # Both shapes mirror the canonical preload chain in
  # `UserFieldPreloads#user_field_preloads` + the dashboard subscribe
  # controllers, so a future refactor can lift them into a shared helper.
  def index
    @preloaded_subscribe_user_ids = preloaded_subscribe_user_ids
    @page, @subscribers = pagy @collection.subscribers.includes(*user_field_preloads_chain)
  end

  private

  # Same `authorization + avatar_attachment + variant_records` chain used
  # in `UserFieldPreloads#user_field_preloads`. Kept inline (not via the
  # concern) because `Collections::BaseController` does not currently
  # include `UserFieldPreloads` and the only consumer is this single
  # action — promoting it to the base would be premature.
  def user_field_preloads_chain
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

  # Set of `User#id`s that `current_user` is subscribed to, in a single
  # SELECT. `current_user` may be nil (this endpoint is public), so the
  # helper returns an empty Set for guests and falls back to the live
  # `subscribe_user?` query per row — same convention as
  # `Users::BaseController#preloaded_subscribe_user_ids`.
  def preloaded_subscribe_user_ids
    return @preloaded_subscribe_user_ids if defined?(@preloaded_subscribe_user_ids)
    @preloaded_subscribe_user_ids =
      if current_user
        current_user.subscribe_user_actions.pluck(:target_id).to_set
      else
        Set.new
      end
  end
end
