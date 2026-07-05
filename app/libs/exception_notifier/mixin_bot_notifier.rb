# frozen_string_literal: true

module ExceptionNotifier
  class MixinBotNotifier < ExceptionNotifier::BaseNotifier
    def initialize(options)
      super
      @bot = options[:bot].constantize
      @conversation_id = options[:conversation_id]
    end

    def call(exception, options = {})
      return if @conversation_id.blank?
      return if MixinApi::ErrorNotification.skip?(exception)

      msg = @bot.api.plain_post(
        conversation_id: @conversation_id,
        data: build_message(exception, options)
      )

      MixinMessages::SendJob.perform_later msg.stringify_keys
    rescue StandardError => e
      Rails.logger.error(
        format(
          "[ExceptionNotifier::MixinBotNotifier] delivery failed (%<class>s: %<message>s) for %<exception>s",
          class: e.class.name,
          message: e.message,
          exception: exception.class.name
        )
      )
    end

    private

    def build_message(exception, options)
      env = options[:env]
      formatted_message = ExceptionNotifier::Formatter.new exception, options

      data = if env.nil?
               options[:data] || {}
      else
               (env["exception_notifier.exception_data"] || {}).merge(options[:data] || {})
      end
      data_string = []
      data_string << "```"
      data.each { |k, v| data_string << "* #{k}: #{v.inspect}" }
      data_string << "```"
      data_string = data_string.join("\n")

      <<~TEXT
        # Quill #{formatted_message.title}

        #{formatted_message.subtitle}

        ## Request

        #{formatted_message.request_message}

        ```
        #{formatted_message.controller_and_action}
        ```

        ## Data

        #{data_string}

        ## Backtrace

        #{formatted_message.backtrace_message}
      TEXT
    end
  end
end
