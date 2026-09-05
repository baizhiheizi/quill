# frozen_string_literal: true

class Collections::SubscribersController < Collections::BaseController
  # The subscriber list renders two partials that each fire per-row
  # queries without preloads:
  #
  #   - `shared/_avatar` reads `subscriber.avatar_image_thumb` and
  #     `_url`, which load `authorization`, `avatar_attachment`,
  #     `blob`, `variant_records`, and `preview_image_attachment`.
  #     Without preloads every subscriber fires ~5 SELECTs, so the
  #     chain is included via `User::AVATAR_PRELOADS`.
  #   - `subscribe_users/_subscribe_button` calls
  #     `current_user.subscribe_user?(user)` per row (action_store
  #     fires one SELECT per call) unless `@preloaded_subscribe_user_ids`
  #     is set in the controller — primed from `ViewerActionSets#ids_for`.
  def index
    @preloaded_subscribe_user_ids = ids_for(:subscribe_user)
    @page, @subscribers = pagy @collection.subscribers.includes(*User::AVATAR_PRELOADS)
  end
end
