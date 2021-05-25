# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_accounts
#
#  id                    :bigint           not null, primary key
#  account               :string
#  encrypted_private_key :string
#  keystore              :jsonb
#  public_key            :string
#  request_allow_at      :datetime
#  request_denny_at      :datetime
#  status                :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint
#
# Indexes
#
#  index_prs_accounts_on_account  (account) UNIQUE
#  index_prs_accounts_on_user_id  (user_id)
#
require 'test_helper'

class PrsAccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
