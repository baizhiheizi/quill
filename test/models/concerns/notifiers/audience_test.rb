# frozen_string_literal: true

require "test_helper"

module Notifiers
  class AudienceTest < ActiveSupport::TestCase
    setup do
      @author = users(:author)
      @follower = users(:reader_one)
      @other_follower = users(:reader_two)
      @blocked = users(:blocked_reader)
      @article = fresh_article(author: @author)
      @tag = fresh_tag
    end

    # === subscribed_to, User target ===

    test "returns exactly the users subscribed to the target" do
      @follower.create_action :subscribe, target: @author
      @other_follower.create_action :subscribe, target: @author
      @blocked.create_action :subscribe, target: @other_follower

      assert_equal [ @follower.id, @other_follower.id ].sort,
                   Notifiers::Audience.subscribed_to(@author).pluck(:id).sort
    end

    test "scopes by target_id, ignoring subscribers of another user" do
      @follower.create_action :subscribe, target: @other_follower

      assert_empty Notifiers::Audience.subscribed_to(@author)
    end

    test "excluding_blocked drops users the target user has blocked" do
      # @author -> @follower block, so @follower subscribed to @author must go.
      @follower.create_action :subscribe, target: @author
      @other_follower.create_action :subscribe, target: @author
      @author.create_action :block, target: @follower

      assert_equal [ @other_follower.id ],
                   Notifiers::Audience.subscribed_to(@author, excluding_blocked: @author).pluck(:id)
    end

    test "keeps subscribers who blocked the target user" do
      # The recipient-side direction is the notifier's `should_notify?` (see
      # PR #2078), not this subquery — the seam keeps the two apart.
      @follower.create_action :subscribe, target: @author
      @follower.create_action :block, target: @author

      assert_equal [ @follower.id ],
                   Notifiers::Audience.subscribed_to(@author, excluding_blocked: @author).pluck(:id)
    end

    test "block rules hold in both directions at once" do
      @follower.create_action :subscribe, target: @author
      @other_follower.create_action :subscribe, target: @author
      @blocked.create_action :subscribe, target: @author
      @author.create_action :block, target: @follower      # author -> follower
      @blocked.create_action :block, target: @author       # follower -> author

      assert_equal [ @other_follower.id, @blocked.id ].sort,
                   Notifiers::Audience.subscribed_to(@author, excluding_blocked: @author).pluck(:id).sort
    end

    # === subscribed_to, Tag target ===

    test "scopes by target_type, so user-subscribers never receive tag events" do
      @follower.create_action :subscribe, target: @author

      assert_empty Notifiers::Audience.subscribed_to(@tag, excluding_blocked: @author)
    end

    test "returns the tag's watchers, minus users the author has blocked" do
      @follower.create_action :subscribe, target: @tag
      @blocked.create_action :subscribe, target: @tag
      @author.create_action :block, target: @blocked

      assert_equal [ @follower.id ],
                   Notifiers::Audience.subscribed_to(@tag, excluding_blocked: @author).pluck(:id)
    end

    # === commenting_subscribers_of ===

    test "returns the users commenting-subscribed to the article" do
      @follower.create_action :commenting_subscribe, target: @article

      assert_equal [ @follower.id ],
                   Notifiers::Audience.commenting_subscribers_of(@article).pluck(:id)
    end

    test "excluding drops the comment author, so an author never echoes themselves" do
      @follower.create_action :commenting_subscribe, target: @article
      @author.create_action :commenting_subscribe, target: @article

      assert_equal [ @follower.id ],
                   Notifiers::Audience.commenting_subscribers_of(@article, excluding: @author).pluck(:id)
    end

    test "returns nobody for a commentable that is not an article" do
      assert_nil Notifiers::Audience.commenting_subscribers_of(@author, excluding: @author)
    end

    # === SQL preservation ===
    #
    # The seam is a move, not a rewrite: every relation below is asserted
    # against the SQL the pre-#2073 call sites composed by hand.

    test "subscribed_to with the block filter matches the Article/Collection composition" do
      expected = User
        .where(id: Action.where(target_type: "User", target_id: @author.id, action_type: "subscribe").select(:user_id))
        .where.not(id: Action.where(user_type: "User", user_id: @author.id, target_type: "User", action_type: "block").select(:target_id))

      assert_equal expected.to_sql, Notifiers::Audience.subscribed_to(@author, excluding_blocked: @author).to_sql
    end

    test "subscribed_to without the block filter matches the Order composition" do
      expected = User.where(id: Action.where(target_type: "User", target_id: @follower.id, action_type: "subscribe").select(:user_id))

      assert_equal expected.to_sql, Notifiers::Audience.subscribed_to(@follower).to_sql
    end

    test "subscribed_to with a Tag target matches the Tagging composition" do
      expected = User
        .where(id: Action.where(target_type: "Tag", target_id: @tag.id, action_type: "subscribe").select(:user_id))
        .where.not(id: @author.blocked_user_ids_relation)

      assert_equal expected.to_sql, Notifiers::Audience.subscribed_to(@tag, excluding_blocked: @author).to_sql
    end

    test "block subquery is a NOT IN subquery, never a materialised id list" do
      sql = Notifiers::Audience.subscribed_to(@author, excluding_blocked: @author).to_sql

      assert_includes sql, 'IN (SELECT "actions"."user_id" FROM "actions"'
      assert_includes sql, 'NOT IN (SELECT "actions"."target_id"'
    end

    test "User#subscribed_user_ids_relation and blocked_user_ids_relation are aliases of the audience subqueries" do
      assert_equal Notifiers::Audience.subscriber_ids_of(@author).to_sql, @author.subscribed_user_ids_relation.to_sql
      assert_equal Notifiers::Audience.blocked_ids_of(@author).to_sql, @author.blocked_user_ids_relation.to_sql
    end

    private

    def fresh_article(author:)
      article = Article.new(
        uuid: SecureRandom.uuid,
        title: "audience seam",
        intro: "intro",
        author: author,
        asset_id: Currency::BTC_ASSET_ID,
        price: 0.001,
        locale: "en",
        free_content_ratio: 0.1,
        readers_revenue_ratio: 0.4,
        platform_revenue_ratio: 0.1,
        author_revenue_ratio: 0.5,
        references_revenue_ratio: 0.0
      )
      article.content = "<p>audience</p>"
      article.save!
      article
    end

    def fresh_tag
      Tag.create!(name: "audience-#{SecureRandom.hex(2)}", locale: "en")
    end
  end
end
