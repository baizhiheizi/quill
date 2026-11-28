# frozen_string_literal: true

module TagHelper
  # "Has the viewer subscribed to this tag?" — answered from the primed
  # action-id set the controller hands down (`ViewerActionSets#ids_for`), so a
  # list of rows costs one SELECT instead of one per row. The set holds
  # *every* tag the viewer subscribed to, so it answers the "no" case as well
  # as the "yes" case. When no controller primed the set (the single-tag
  # surfaces and the subscribe/destroy turbo-stream frames), fall back to the
  # live check: one row, one query.
  def viewer_subscribed_to_tag?(tag)
    ids = @preloaded_subscribe_tag_ids
    return current_user.subscribe_tag?(tag) if ids.nil?

    ids.include?(tag.id)
  end
end
