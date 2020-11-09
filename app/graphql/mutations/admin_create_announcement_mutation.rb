# frozen_string_literal: true

module Mutations
  class AdminCreateAnnouncementMutation < AdminBaseMutation
    argument :content, String, required: true
    argument :message_type, String, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(params)
      Announcement.create!(
        content: params[:content],
        message_type: params[:message_type]
      )

      {
        success: true
      }
    rescue StandardError => e
      {
        error: e.to_s
      }
    end
  end
end
