# frozen_string_literal: true

module Resolvers
  class AdminAnnouncementConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::AnnouncementConnectionType, null: false

    def resolve(_params = {})
      Announcement.all.order(created_at: :desc)
    end
  end
end
