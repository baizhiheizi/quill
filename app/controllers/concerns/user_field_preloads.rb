# frozen_string_literal: true

# Shared preload chain for partials that render `shared/avatar` or
# `admin/users/_field`. Both partials read `user.avatar_image_thumb` (or
# `_url`), which loads two pieces of state we want preloaded together so
# `Order.includes(buyer: UserFieldPreloads.preloads)` can serve the index
# page in O(1) SELECTs instead of firing one per row.
#
# The chain mirrors `Admin::BaseController#admin_user_field_preloads` (kept
# aliased below for backwards compatibility — admin controllers still call
# `admin_user_field_preloads` inline). It is intentionally identical so
# partials can render the same `shared/_avatar` shape across the admin
# and dashboard surfaces without one path firing extra queries.
#
# Pieces:
#   - `:authorization` → `User#avatar_image_thumb` falls back to
#     `authorization.raw["avatar_url"]` when no `ActiveStorage::Attachment`
#     is attached (covers OAuth-only Mixin users without an uploaded avatar).
#   - `avatar_attachment: { blob: { ... } }` → resolves `attached?` from
#     the `Attachment` row and `avatar.variant(:thumb).processed.key` from
#     the preloaded `Blob` + `VariantRecord` chains. Without these preloads
#     each row triggers 2-3 SELECTs (attachment + blob + variant_record).
module UserFieldPreloads
  extend ActiveSupport::Concern

  def user_field_preloads
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
