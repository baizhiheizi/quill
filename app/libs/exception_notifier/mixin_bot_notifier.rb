# frozen_string_literal: true

module ExceptionNotifier
  class MixinBotNotifier < ExceptionNotifier::BaseNotifier
    def initialize(options)
      super
      @bot = options[:bot].constantize
      @recipient_id = options[:recipient_id]
      @conversation_id = options[:conversation_id] || @bot.api.unique_uuid(@recipient_id)
    end

    def call(exception, options = {})
      return if @conversation_id.blank?

      msg = @bot.api.plain_post(
        conversation_id: @conversation_id,
        data: build_message(exception, options)
      )

      SendMixinMessageWorker.perform_async msg
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

        #{request_message(env)}

        ## Controller & Action

        ```
        #{formatted_message.controller_and_action}
        ```

        ## Data

        #{data_string}

        ## Backtrace

        #{formatted_message.backtrace_message}
      TEXT
    end

    def request_message(env)
      request = ActionDispatch::Request.new(env) if env
      return unless request

      [
        '```',
        "* url : #{request.original_url}",
        "* http_method : #{request.method}",
        "* ip_address : #{request.remote_ip}",
        "* parameters : #{request.filtered_parameters}",
        "* user_agent : #{request.user_agent}",
        "* timestamp : #{Time.current}",
        '```'
      ].join("\n")
    end
  end
end
