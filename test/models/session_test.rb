# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
# Database name: primary
#
#  id         :bigint           not null, primary key
#  info       :json
#  uuid       :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#  index_sessions_on_uuid     (uuid) UNIQUE
#
require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "removed dead scopes stay removed" do
    # Pin the third-round dead-scope sweep (PR #1896 cleanup). `with_user`
    # was declared but unused across app/, lib/, and test/; callers use the
    # plain `Session.includes(:user)` shape (or just `find`/`find_by`). Seeing
    # `Session.with_user` re-added without an accompanying caller is the
    # regression this assertion catches.
    refute_includes Session.singleton_methods(false), :with_user
  end
end
