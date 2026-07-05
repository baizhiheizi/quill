# frozen_string_literal: true

module MixinApi
  module ErrorNotification
    module_function

    def skip?(error)
      return true if error.respond_to?(:throttle?) && error.throttle?
      return true if MixinBot.retryable?(error)
      return true if error.is_a?(MixinBot::HttpError) || error.is_a?(MixinBot::RequestError)
      return true if error.is_a?(OpenSSL::SSL::SSLError)

      false
    end

    def log_skipped(error, context: nil)
      prefix = context.present? ? "[#{context}] " : ""
      Rails.logger.warn(
        format(
          "%<prefix>sSkipped Mixin bot exception notification (%<class>s: %<message>s)",
          prefix: prefix,
          class: error.class.name,
          message: error.message
        )
      )
    end

    def notify_unless_mixin_api(error, options = {}, context: nil)
      if skip?(error)
        log_skipped(error, context: context)
        return
      end

      ExceptionNotifier.notify_exception(error, options)
    end
  end
end
