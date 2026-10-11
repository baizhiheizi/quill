# frozen_string_literal: true

class TaggingCreatedNotifier < ApplicationNotifier
  notifies :tagging_created

  required_param :tagging

  notification_methods do
    def tagging
      params[:tagging]
    end

    delegate :article, to: :tagging

    def icon_url
      ApplicationNotifier::QUILL_ICON_URL
    end

    def title
      article.title
    end

    def description
      [ "##{tagging.tag.name}", t(".has_new_article") ].join(" ")
    end

    def message
      [ "##{tagging.tag.name}", t(".has_new_article"), article.title ].join(" ")
    end

    def url
      user_article_url article.author, article.uuid
    end

    def should_notify?
      !recipient.block_user? article.author
    end
  end
end
