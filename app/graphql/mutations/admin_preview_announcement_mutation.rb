# frozen_string_literal: true

module Mutations
  class AdminPreviewAnnouncementMutation < AdminBaseMutation
    argument :id, Int, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(params)
      Announcement.find_by(id: params[:id])&.preview
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
