# frozen_string_literal: true

require "test_helper"

# Pins `ViewerActionSets#ids_for`, the single owner of the per-viewer
# action-id sets. Before this concern, the set-building helper existed as
# three verbatim copies under four names across the dashboard, users and
# collections namespaces plus the upvote/downvote pair in
# `ArticlesController` — and the copies disagreed on the guest case: the
# public surfaces returned an empty `Set`, while the dashboard copies would
# have raised `NoMethodError` on `nil` the moment they were reached without a
# signed-in viewer.
#
# The harness below is the smallest object that satisfies the concern's
# contract — it only supplies `current_user` — so these assertions test the
# concern itself rather than any one controller. The per-controller wiring is
# covered by the controller tests (`Dashboard::SubscribeUsersControllerTest`,
# `Dashboard::BlockUsersControllerTest`, `ArticlesControllerTest`), which
# assert on the instance variables their partials read.
class ViewerActionSetsTest < ActiveSupport::TestCase
  # verb → the `action_store` action that seeds it plus the kind of target
  # that action accepts (`action_store` filters each relation by
  # `target_type`, so `upvote_article` must be seeded with an Article, not a
  # User). All four verbs are swept by every "across all four verbs"
  # assertion below.
  VERBS = {
    subscribe_user: { action: :subscribe, target_kind: :user },
    block_user: { action: :block, target_kind: :user },
    upvote_article: { action: :upvote, target_kind: :article },
    downvote_article: { action: :downvote, target_kind: :article }
  }.freeze

  def target_for(kind)
    kind == :user ? users(:reader_one) : articles(:published_free)
  end

  # Every controller that renders a partial consulting a preloaded action set
  # must still expose the helper. A base controller dropping the include
  # fails here instead of surfacing as a `NoMethodError` mid-render.
  CONSUMERS = %w[
    ArticlesController
    Dashboard::SubscribeUsersController
    Dashboard::BlockUsersController
    Users::SubscribeUsersController
    Users::SubscribeByUsersController
    Collections::SubscribersController
  ].freeze

  test "returns the acted-on ids for a signed-in viewer across all four verbs" do
    viewer = users(:author)

    VERBS.each do |verb, spec|
      acted = target_for(spec[:target_kind])
      viewer.create_action(spec[:action], target: acted)

      ids = harness(viewer).send(:ids_for, verb)

      assert_instance_of Set, ids, "#{verb}: expected a Set, got #{ids.class}"
      assert_includes ids, acted.id, "#{verb}: expected the acted-on id in the set"
    end
  end

  test "keeps the verbs separate — one action type never leaks into another" do
    viewer = users(:author)
    target = target_for(:user)
    viewer.create_action(:subscribe, target: target)

    subject = harness(viewer)

    # Only :subscribe_user may see a `subscribe` row; the other three verbs
    # read `Action` rows with their own action_type/target_type and must stay
    # empty even though a User target is in the table.
    assert_includes subject.send(:ids_for, :subscribe_user), target.id
    VERBS.each_key do |verb|
      next if verb == :subscribe_user

      assert_empty subject.send(:ids_for, verb), "#{verb}: expected no rows for a subscribe action"
    end
  end

  test "returns an empty set for a guest across all four verbs" do
    VERBS.each_key do |verb|
      ids = harness(nil).send(:ids_for, verb)

      assert_instance_of Set, ids, "#{verb}: expected a Set for a guest, got #{ids.class}"
      assert_empty ids, "#{verb}: expected an empty set for a guest"
    end
  end

  test "a guest is answered without touching the actions table" do
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql] =~ /FROM\s+"actions"/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      VERBS.each_key { |verb| harness(nil).send(:ids_for, verb) }
    end

    assert_empty queries,
      "a guest must be answered without a query, got: #{queries.inspect}"
  end

  test "memoizes one SELECT per verb across repeated calls" do
    viewer = users(:author)
    viewer.create_action(:subscribe, target: users(:reader_one))

    subject = harness(viewer)
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql] =~ /FROM\s+"actions"/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      4.times { subject.send(:ids_for, :subscribe_user) }
    end

    assert_equal 1, queries.size,
      "expected a single actions SELECT for repeated lookups, got #{queries.size}:\n#{queries.join("\n")}"
  end

  test "caches each verb in its own slot" do
    viewer = users(:author)
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)
    viewer.create_action(:subscribe, target: reader_one)
    viewer.create_action(:block, target: reader_two)
    viewer.create_action(:upvote, target: articles(:published_free))
    viewer.create_action(:downvote, target: articles(:published_free))

    subject = harness(viewer)
    subscribe_ids = subject.send(:ids_for, :subscribe_user)
    block_ids = subject.send(:ids_for, :block_user)

    assert_includes subscribe_ids, reader_one.id
    assert_not_includes subscribe_ids, reader_two.id
    assert_includes block_ids, reader_two.id
    assert_not_includes block_ids, reader_one.id
    assert_not_equal subscribe_ids, block_ids, "the two verbs must not share a memoization slot"
    assert_not_equal subscribe_ids, subject.send(:ids_for, :upvote_article), "each verb needs its own slot"
  end

  test "raises for a verb the concern does not own" do
    error = assert_raises(ArgumentError) { harness(users(:author)).send(:ids_for, :hug_user) }

    assert_match(/hug_user/, error.message)
  end

  test "every consuming controller still exposes the helper" do
    CONSUMERS.each do |name|
      controller = name.constantize.new

      assert controller.respond_to?(:ids_for, true),
        "#{name} should include ViewerActionSets — its partials read a preloaded action set"
    end
  end

  private

  # Minimal host for the concern. `ids_for` needs nothing else: it reads
  # `current_user` and talks to `User`'s action_store relations.
  def harness(current_user)
    Class.new do
      include ViewerActionSets

      def initialize(current_user)
        @current_user = current_user
      end

      def current_user
        @current_user
      end
    end.new(current_user)
  end
end
