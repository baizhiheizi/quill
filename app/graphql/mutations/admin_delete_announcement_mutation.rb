# frozen_string_literal: true

module Mutations
  class AdminDeleteAnnouncementMutation < AdminBaseMutation
    argument :id, Int, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(id:)
      Announcement.find_by(id: id)&.destroy!

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
