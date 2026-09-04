# frozen_string_literal: true

module Users::Statable
  extend ActiveSupport::Concern

  # The aggregate columns this concern memoizes. The memoization keys are
  # owned here and nowhere else: both the per-instance readers and the bulk
  # preloader go through `#memoized_statable` / `#memoize_statable`, so an
  # unknown key is a bug rather than a silently-wrong value.
  AGGREGATES = %i[
    bought_articles_count
    payment_total_usd
    author_revenue_total_usd
    reader_revenue_total_usd
    revenue_total_usd
  ].freeze

  # Namespaced memoization slot for this concern's aggregates. The `statable_`
  # prefix keeps the ivars owned by `Users::Statable` instead of squatting on
  # generic names (`@bought_articles_count`) that a controller could
  # accidentally collide with — or, worse, deliberately prime from outside the
  # model without the concern knowing.
  STATABLE_MEMO_PREFIX = "@statable_"

  class_methods do
    # Bulk entry point for the aggregate columns. `Admin::UsersController#index`
    # renders `bought_articles_count`, `payment_total_usd` and
    # `author_revenue_total_usd` once per row from
    # `app/views/admin/users/_user.html.erb`, and the naive per-user readers
    # each fire one SQL query (count / sum / joined-sum) — a 24-user page cost
    # ~72 queries just for these three columns, and the joined-sum is the
    # slowest of the three.
    #
    # This collapses those N×3 queries into **3 batched GROUP BY queries** and
    # primes the concern's own memoization, so the subsequent
    # `user.bought_articles_count` calls in the view return the precomputed
    # values without touching the DB.
    #
    # The aggregation semantics are unchanged from the per-user readers:
    #   - `bought_articles_count`   → count of `Order` rows where
    #     `order_type: :buy_article` for that `buyer_id` (matches
    #     `User#bought_articles`, which is `has_many :through` → `buy_orders`
    #     filtered by `order_type`).
    #   - `payment_total_usd`       → `SUM(orders.value_usd)` for that
    #     `buyer_id`. `value_usd` is snapshotted on the Order at create time,
    #     so the per-buyer sum is equivalent to summing all of the buyer's
    #     order rows. Note it sums *every* order, not only buy orders — the
    #     per-user reader does the same.
    #   - `author_revenue_total_usd` → `SUM(amount * currencies.price_usd)`
    #     over `transfers` with `transfer_type: :author_revenue`, grouped by
    #     `opponent_id` (the recipient's `mixin_uuid`).
    #
    # Only the three columns a list actually renders are batched; the other
    # `AGGREGATES` keys still compute lazily per user. Returns `users` so the
    # call sites stay one line, and is a no-op on an empty collection so an
    # empty result set never adds queries.
    def preload_aggregates(users)
      return if users.blank?

      user_ids = users.map(&:id)
      mixin_uuids = users.map(&:mixin_uuid).compact

      bought_by_buyer_id = Order
        .where(order_type: :buy_article, buyer_id: user_ids)
        .group(:buyer_id)
        .count

      payment_by_buyer_id = Order
        .where(buyer_id: user_ids)
        .group(:buyer_id)
        .sum(:value_usd)

      author_revenue_by_opponent_id = Transfer
        .joins(:currency)
        .where(transfer_type: :author_revenue, opponent_id: mixin_uuids)
        .group(:opponent_id)
        .sum("amount * currencies.price_usd")

      users.each do |user|
        # `send` is deliberate: `#memoize_statable` is private because it is
        # the concern's own memoization contract. Priming it from here (the
        # concern that owns the keys) is the *only* sanctioned path — no
        # controller may write these values.
        user.send(:memoize_statable, :bought_articles_count, bought_by_buyer_id[user.id] || 0)
        user.send(:memoize_statable, :payment_total_usd, (payment_by_buyer_id[user.id] || 0).to_f)
        user.send(:memoize_statable, :author_revenue_total_usd, (author_revenue_by_opponent_id[user.mixin_uuid] || 0).to_f)
      end

      users
    end
  end

  # Counts unread notifications that are visible in the web inbox. Visibility
  # is denormalised onto `noticed_notifications.web_visible` at creation, so
  # this is an indexed `count` — and, unlike the earlier implementations, it
  # agrees with the index instead of overcounting by the muted kinds.
  def unread_notifications_count
    notifications.unread.for_web.count
  end

  def has_unread_notification?
    notifications.unread.for_web.exists?
  end

  # `articles_count` / `comments_count` are counter-cache columns on `users`
  # maintained by `Article#belongs_to :author, counter_cache: true` and the
  # matching declaration on `Comment`. Reads are O(1) — no SQL needed when
  # the user record is already in memory.
  def articles_count
    read_attribute(:articles_count)
  end

  def bought_articles_count
    memoized_statable(:bought_articles_count) { bought_articles.count }
  end

  def comments_count
    read_attribute(:comments_count)
  end

  def payment_total_usd
    memoized_statable(:payment_total_usd) { orders.sum(:value_usd).to_f }
  end

  def author_revenue_total_usd
    memoized_statable(:author_revenue_total_usd) do
      transfers.joins(:currency).where(transfer_type: :author_revenue).sum("amount * currencies.price_usd").to_f
    end
  end

  def reader_revenue_total_usd
    memoized_statable(:reader_revenue_total_usd) do
      transfers.joins(:currency).where(transfer_type: :reader_revenue).sum("amount * currencies.price_usd").to_f
    end
  end

  def revenue_total_usd
    memoized_statable(:revenue_total_usd) do
      transfers.joins(:currency).where(transfer_type: %i[author_revenue reader_revenue]).sum("amount * currencies.price_usd").to_f
    end
  end

  def validated?
    validated_at?
  end

  def validate!
    update validated_at: Time.current, blocked_at: nil
  end

  def unvalidate!
    update validated_at: nil
  end

  def blocked?
    blocked_at?
  end

  def block!
    update blocked_at: Time.current, validated_at: nil
  end

  def unblock!
    update blocked_at: nil
  end

  def messenger?
    authorization&.provider == "mixin"
  end

  def accessable?
    return true unless Settings.whitelist&.enable

    mixin_uuid.in? (Settings.whitelist&.mixin_id || []).map(&:to_s)
  end

  def twitter_username
    raw = twitter_authorization&.raw
    return unless raw.is_a?(Hash)

    username = raw["username"].presence || raw["screen_name"].presence
    return unless username.is_a?(String) || username.is_a?(Symbol)

    username.to_s.strip.delete_prefix("@").presence
  end

  def twitter_connected?
    twitter_username.present?
  end

  def twitter_profile_url
    username = twitter_username
    return if username.blank?

    Addressable::URI.new(
      scheme: "https",
      host: "twitter.com",
      path: "/#{username}"
    ).to_s
  end

  private

  # Read-then-compute for an aggregate. Values are counts and USD sums, so a
  # memoized `0` / `0.0` is truthy and `||` never recomputes a primed zero.
  def memoized_statable(key)
    ivar = STATABLE_MEMO_PREFIX + key.to_s
    instance_variable_get(ivar) || instance_variable_set(ivar, yield)
  end

  # Prime one aggregate from outside the per-user query path. Only reachable
  # via `User.preload_aggregates`; an unknown key raises rather than silently
  # memoizing a value no reader will ever see.
  def memoize_statable(key, value)
    raise ArgumentError, "unknown Users::Statable aggregate #{key.inspect}" unless AGGREGATES.include?(key)

    instance_variable_set(STATABLE_MEMO_PREFIX + key.to_s, value)
  end
end
