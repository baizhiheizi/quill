# frozen_string_literal: true

# One owner for the per-viewer action-id sets that list and panel partials
# consult to answer "has the viewer already done this?" without firing a
# SELECT per row.
#
# `action_store` generates a `has_many :<action>_<target>_actions` relation on
# `User`, and the natural per-row check (`current_user.subscribe_user?(user)`)
# is `Action.find_by(...).present?` — one SELECT per row. Partials therefore
# receive a preloaded `Set` of ids from the controller instead. Every surface
# used to define that set-building helper itself: the dashboard subscribe and
# block controllers, `Users::BaseController`,
# `Collections::SubscribersController`, and the upvote/downvote pair in
# `ArticlesController` — four namespaces, three of them carrying verbatim
# copies, two of them drifting on the guest case.
#
# `ids_for` is the single verb. Assign its result to the instance variable the
# partial already reads, so views stay untouched:
#
#     @preloaded_subscribe_user_ids = ids_for(:subscribe_user)
module ViewerActionSets
  extend ActiveSupport::Concern

  # verb → the `action_store`-generated relation on `User`. Kept explicit
  # rather than built from "#{verb}_actions" so the supported set is greppable
  # and an unsupported verb fails loudly at the lookup.
  ACTION_RELATIONS = {
    subscribe_user: :subscribe_user_actions,
    block_user: :block_user_actions,
    upvote_article: :upvote_article_actions,
    downvote_article: :downvote_article_actions
  }.freeze

  private

  # Set of `target_id`s the viewer has acted on with `verb`, resolved in one
  # SELECT and memoized for the rest of the request. `.to_set` makes the
  # per-row `include?` check O(1); `pluck` means the `Action` rows are never
  # instantiated.
  #
  # Uniform guest semantics: a nil `current_user` returns an empty Set and
  # fires **no query**. Every consumer of this helper is either public (the
  # article show page, user pages, collection subscribers) or behind
  # `authenticate_user!` (the dashboard), so the guest branch is a safety net
  # rather than a hot path — but it is the same branch everywhere, instead of
  # `Set.new` in some copies and a latent `NoMethodError` on `nil` in others.
  # The public partials fall through to the live per-row helper for guests and
  # stay correct.
  def ids_for(verb)
    relation = ACTION_RELATIONS.fetch(verb) do
      raise ArgumentError, "unsupported viewer action #{verb.inspect}; expected one of #{ACTION_RELATIONS.keys.inspect}"
    end

    viewer_action_sets[verb] ||= if current_user
      current_user.public_send(relation).pluck(:target_id).to_set
    else
      Set.new
    end
  end

  # Per-request cache. One slot per verb, so a page that consults the same set
  # through several partials still only ever runs one SELECT.
  def viewer_action_sets
    @viewer_action_sets ||= {}
  end
end
