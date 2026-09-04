# frozen_string_literal: true

# The one declaration of every notification kind Quill sends.
#
# Facts that are true for a whole kind live here instead of being re-declared
# in the notifier, the settings model, the strong params and the settings form:
#
#   * `ApplicationNotifier` derives the `deliver_by :mixin_bot` config, the
#     inbox visibility written onto every `noticed_notifications` row, and the
#     per-recipient delivery guards from a kind.
#   * `NotificationSetting` derives its store columns, defaults and casts.
#   * The settings strong params and the settings form rows are loops over
#     `with_settings`.
#
# A kind is reachable from a persisted row through `notifier` / `type` — both
# plain strings, so "is this row web visible?" never needs `constantize`.
#
# Adding a notification: add an entry here, create the notifier class and call
# `notifies :the_name` from it, then add the `notifiers.<notifier>` translations.
class NotificationKind
  # Delivery channels a recipient can switch on or off per kind.
  CHANNELS = %i[web mixin_bot].freeze

  class NotFoundError < NameError; end

  attr_reader :name, :category, :settings_key, :bot, :position

  # +name+     — the kind; also the settings column and the settings form label.
  # +category+ — `:card` renders a Mixin APP_CARD, `:text` a plain message.
  # +settings+ — whether the recipient can mute the kind per channel.
  # +web+      — whether the kind ever surfaces in the web inbox.
  # +bot+      — the Mixin bot carrying the message (defaults to QuillBot).
  # +position+ — where the kind sits in the settings form.
  def initialize(name, category:, settings: false, web: true, bot: nil, position: nil)
    @name = name.to_sym
    @category = category
    @settings_key = settings ? @name : nil
    @web = web
    @bot = bot
    @position = position
    freeze
  end

  def card? = category == :card
  def web? = @web
  def settings? = !settings_key.nil?
  def notifier = "#{name.to_s.camelize}Notifier"
  def notification_type = "#{notifier}::Notification"
  def mixin_category = card? ? "APP_CARD" : "PLAIN_TEXT"
  def setting_key(channel) = :"#{settings_key}_#{channel}"

  def self.all = ALL
  def self.fetch(name) = BY_NAME.fetch(name.to_sym) { raise NotFoundError, "unknown notification kind: #{name.inspect}" }

  # Kinds a recipient can mute, in the order the settings form renders them.
  def self.with_settings = WITH_SETTINGS

  def self.settings_defaults
    WITH_SETTINGS.each_with_object({}) do |kind, defaults|
      CHANNELS.each { |channel| defaults[kind.setting_key(channel)] = true }
    end.freeze
  end

  def self.permittable_settings = WITH_SETTINGS.flat_map { |kind| CHANNELS.map { |channel| kind.setting_key(channel) } }.freeze

  # Persisted `type` strings that belong in the web inbox. Anything else — the
  # Mixin-only kinds and types orphaned by a renamed notifier — does not.
  def self.web_visible_notification_types = ALL.select(&:web?).map(&:notification_type).freeze

  ALL = [
    new(:article_published, category: :card, settings: true, position: 1),
    new(:article_bought, category: :card, settings: true, position: 2),
    new(:article_rewarded, category: :card, settings: true, position: 3),
    new(:tagging_created, category: :card, settings: true, position: 4),
    new(:comment_created, category: :card, settings: true, position: 5),
    new(:transfer_processed, category: :card, settings: true, bot: "RevenueBot", position: 6),
    new(:collection_listed, category: :card, settings: true, position: 7),
    new(:collection_bought, category: :card, settings: true, position: 8),
    new(:order_created, category: :text),
    new(:payment_created, category: :text),
    new(:payment_refunded, category: :text),
    new(:subscribe_user_action_created, category: :text),
    new(:user_connected, category: :text, web: false),
    new(:user_safe_registration, category: :text, web: false)
  ].freeze

  private_constant :ALL

  BY_NAME = ALL.index_by(&:name).freeze

  private_constant :BY_NAME

  WITH_SETTINGS = ALL.select(&:settings?).sort_by(&:position).freeze

  private_constant :WITH_SETTINGS
end
