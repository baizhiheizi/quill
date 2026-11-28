# frozen_string_literal: true

module UserHelper
  def avatar_initials(name)
    return "?" if name.blank?

    tokens = name.strip.split(/\s+/).reject(&:blank?)
    return "?" if tokens.empty?

    tokens.first(2).map { |token| token.each_grapheme_cluster.first }.join.upcase
  end

  # "Has the viewer subscribed to this user?" — answered from the primed
  # action-id set the controller hands down (`ViewerActionSets#ids_for`), so a
  # list of rows costs one SELECT instead of one per row.
  #
  # The set holds *every* target the viewer subscribed to, so it answers the
  # "no" case as well as the "yes" case — which is what lets a list of
  # subscribers (rows the viewer did *not* subscribe to) skip the live
  # `action_store` check entirely. When no controller primed the set (the
  # guest-facing surfaces and the subscribe/destroy turbo-stream frames),
  # fall back to the live check: one row, one query.
  def viewer_subscribed_to?(user)
    ids = @preloaded_subscribe_user_ids
    return current_user.subscribe_user?(user) if ids.nil?

    ids.include?(user.id)
  end
end
