# frozen_string_literal: true

module Users::Statable
  extend ActiveSupport::Concern

  # Counts unread non-mixin-only notifications. Replaces the previous
  # implementation that loaded every matching row into Ruby and filtered via
  # `select(&:visible_in_web?)`; the badge in `_navbar` / `_left_bar` runs on
  # every page render, so the previous version pulled all unread rows just to
  # answer a yes/no question. `for_web` already excludes the two mixin-only
  # notifier types that never show in the web UI; the per-recipient visibility
  # predicate is intentionally not reproduced here — the badge is an indicator
  # and a small overcount (notifications muted via `notification_setting`) is
  # acceptable. The exact visible-only set is still computed on the
  # notifications index (`Dashboard::NotificationsController`).
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
    @bought_articles_count ||= bought_articles.count
  end

  def comments_count
    read_attribute(:comments_count)
  end

  def payment_total_usd
    @payment_total_usd ||= orders.sum(:value_usd).to_f
  end

  def author_revenue_total_usd
    @author_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :author_revenue).sum("amount * currencies.price_usd").to_f
  end

  def reader_revenue_total_usd
    @reader_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :reader_revenue).sum("amount * currencies.price_usd").to_f
  end

  def revenue_total_usd
    @revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: %i[author_revenue reader_revenue]).sum("amount * currencies.price_usd").to_f
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
end
