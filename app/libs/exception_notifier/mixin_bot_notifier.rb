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

      msg = @bot.api.plain_post(
        conversation_id: @conversation_id,
        data: build_message(exception, options)
      )

      MixinMessages::SendJob.perform_later msg.stringify_keys
    end

    private

    def build_message(exception, options)
      env = options[:env]
      formatted_message = ExceptionNotifier::Formatter.new exception, options

      data = if env.nil?
               options[:data] || {}
             else
               (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
             end
      data_string = []
      data_string << '```'
      data.each { |k, v| data_string << "* #{k}: #{v.inspect}" }
      data_string << '```'
      data_string = data_string.join("\n")

      <<~TEXT
        # #{formatted_message.title}

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
