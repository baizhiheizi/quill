# frozen_string_literal: true

# `MixinApi.wrap` is defined in gate.rb, which Zeitwerk loads only when
# `MixinApi::Gate` is referenced. Name it here: this module wraps every API it
# builds, and the Blaze process (bin/mixin_blaze) never touches the gate.
require_dependency "mixin_api/gate"

module QuillBot
  # Raised when the Mixin API client fails to build. Callers get a typed error
  # instead of a nil client, so the failure surfaces at its source.
  class ClientUnavailableError < StandardError; end

  def self.api
    @api ||= wrap_api(build_api, mode: :background)
  rescue StandardError => e
    Rails.logger.error e
    raise ClientUnavailableError, e.message
  end

  def self.interactive_api
    wrap_api(build_api, mode: :interactive)
  rescue StandardError => e
    Rails.logger.error e
    raise ClientUnavailableError, e.message
  end

  def self.build_api
    MixinBot::API.new(**Rails.application.credentials[:quill_bot], debug: Rails.env.development?)
  end

  def self.wrap_api(api, mode:)
    MixinApi.wrap(api, scope: :quill_bot, mode: mode)
  end
  private_class_method :build_api, :wrap_api

  # The Blaze feed driven by the standalone process (bin/mixin_blaze). The
  # gem's fiber-based reactor owns connect / keepalive / reconnect; Quill
  # supplies the handler and the ack policy.
  #
  # `:after_handler` acknowledges a message only once `ingest!` has persisted
  # it, so a failure between receipt and the write gets the message redelivered
  # on the next reconnect rather than dropped.
  def self.blaze_reactor
    MixinBot::Blaze::Reactor.new(
      api: api,
      handler: ->(envelope) { ingest_blaze_message envelope },
      ack_policy: :after_handler,
      logger: ->(level, detail) { log_blaze_reactor level, detail }
    )
  end

  def self.ingest_blaze_message(envelope)
    Rails.logger.info [ "Quill", Time.current, :message, envelope["action"] ]
    MixinMessage.ingest! envelope
  end
  private_class_method :ingest_blaze_message

  # Lifecycle lines (connected / closed) are routine; everything else is a
  # failure. Exceptions keep their backtrace.
  def self.log_blaze_reactor(level, detail)
    message = detail.is_a?(Exception) ? "#{detail.inspect}\n#{detail.backtrace&.join("\n")}" : detail
    Rails.logger.public_send(%i[connected closed].include?(level) ? :info : :error, "[mixin_blaze] #{level}: #{message}")
  end
  private_class_method :log_blaze_reactor

  def self.generate_app_report
    <<~TEXT
      ## Quill Report #{Time.current.to_date}

      ### Last 24 Hours
      - New Users: #{User.where(created_at: 24.hours.ago...).count}
      - Articles: #{Article.where(published_at: 24.hours.ago...).count}
      - Orders: #{Order.completed.where(created_at: 24.hours.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 24.hours.ago...).sum(:value_usd).round(4)}

      ### Last 7 days
      - New Users: #{User.where(created_at: 7.days.ago...).count}
      - Articles: #{Article.where(published_at: 7.days.ago...).count}
      - Orders: #{Order.completed.where(created_at: 7.days.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 7.days.ago...).sum(:value_usd).round(4)}

      ### Last 30 days
      - New Users: #{User.where(created_at: 30.days.ago...).count}
      - Articles: #{Article.where(published_at: 30.days.ago...).count}
      - Orders: #{Order.completed.where(created_at: 30.days.ago...).count}
      - Volume: $#{Order.completed.where(updated_at: 30.days.ago...).sum(:value_usd).round(4)}

      ### Total
      - Users: #{User.count}
      - Articles: #{Article.only_published.count}
      - Orders: #{Order.completed.count}
      - Volume: $#{Order.completed.sum(:value_usd).round(4)}
    TEXT
  end
end
