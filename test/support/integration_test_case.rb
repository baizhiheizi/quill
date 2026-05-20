# frozen_string_literal: true

require "test_helper"

class IntegrationTestCase < ActionDispatch::IntegrationTest
  include CommerceHelpers
  include QuillBotStub

  def sign_in(user)
    session_record = Session.create!(
      user: user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    )
    host! "www.example.com"
    get "/up"
    session[:current_session_id] = session_record.uuid
    session_record
  end

end
