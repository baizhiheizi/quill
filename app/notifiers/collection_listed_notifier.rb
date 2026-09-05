# frozen_string_literal: true

class CollectionListedNotifier < ApplicationNotifier
  notifies :collection_listed

  required_param :collection

  notification_methods do
    def collection
      params[:collection]
    end

    def title
      collection.name
    end

    def description
      [ collection.author.name.truncate(10), t(".listed") ].join(" ")
    end

    def message
      [ collection.author.name.truncate(10), t(".listed"), ":", collection.name ].join(" ")
    end

    def url
      collection_url collection.uuid
    end

    def icon_url
      collection.author.avatar_url
    end
  end
end
