# frozen_string_literal: true

# WHO receives an event.
#
# Every audience rule in the app — subscribers, the author's outgoing block
# list, the commenter's self-echo — is composed here, once, in SQL over the
# `actions` table. Delivery sites name the audience they mean instead of
# re-composing it, which is what keeps a fourth hand-rolled variant (the
# `Comment#subscribers` shape before #2073) from coming back.
#
# The subqueries are moved, not rewritten: `Notifiers::AudienceTest` asserts
# the composed relations byte-for-byte against the SQL the pre-seam call sites
# built. No id list is ever materialised in Ruby.
module Notifiers
  module Audience
    module_function

    # Users who `subscribe` to `target` — a User's followers, a Tag's
    # watchers — minus everyone `excluding_blocked` has blocked. The block
    # filter is the author's *outgoing* list; the reverse direction (a
    # recipient who blocked the author) is each notifier's `should_notify?`.
    def subscribed_to(target, excluding_blocked: nil)
      scope = User.where(id: subscriber_ids_of(target))
      return scope if excluding_blocked.blank?

      scope.where.not(id: blocked_ids_of(excluding_blocked))
    end

    # Users who `commenting_subscribe` to `article`, minus `excluding` — the
    # comment author, so an author never echoes themselves.
    #
    # `commenting_subscribe` actions only exist for articles, so any other
    # commentable has no commenting audience and the caller delivers to
    # nobody.
    def commenting_subscribers_of(commentable, excluding: nil)
      return unless commentable.is_a?(Article)

      scope = commentable.commenting_subscribe_by_users
      return scope if excluding.blank?

      scope.where.not(mixin_uuid: excluding.mixin_uuid)
    end

    # SQL subquery: every user_id that subscribed to `target` (a User or a
    # Tag — the action_store gem accepts any target_type). Exposed for the
    # `User#subscribed_user_ids_relation` alias.
    def subscriber_ids_of(target)
      Action.where(target_type: target.class.name, target_id: target.id, action_type: "subscribe").select(:user_id)
    end

    # SQL subquery: every target_id that `user` has blocked (their outgoing
    # list, not the list of who blocked them). Exposed for the
    # `User#blocked_user_ids_relation` alias.
    def blocked_ids_of(user)
      Action.where(user_type: "User", user_id: user.id, target_type: "User", action_type: "block").select(:target_id)
    end
  end
end
