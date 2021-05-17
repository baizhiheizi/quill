# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      verified_user = User.find_by(id: @request.session[:current_user_id])
      reject_unauthorized_connection if verified_user.blank?

      verified_user
    end
  end
end
