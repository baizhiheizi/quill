# frozen_string_literal: true

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connect identifies the current user from a valid session" do
    session = sessions(:reader_session)

    connect session: { current_session_id: session.uuid }

    assert_equal users(:reader_one), connection.current_user
  end

  test "connect identifies the current user from the other valid session fixture" do
    session = sessions(:author_session)

    connect session: { current_session_id: session.uuid }

    assert_equal users(:author), connection.current_user
  end

  test "connect rejects connections when no session is sent" do
    assert_reject_connection { connect }
  end

  test "connect rejects connections when the session uuid is unknown" do
    assert_reject_connection { connect session: { current_session_id: "00000000-0000-4000-8000-000000000000" } }
  end

  test "connect rejects connections when the session uuid is blank" do
    assert_reject_connection { connect session: { current_session_id: "" } }
  end
end
