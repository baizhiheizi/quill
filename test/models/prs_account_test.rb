# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_accounts
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  account               :string
#  status                :string
#  public_key            :string
#  encrypted_private_key :string
#  keystore              :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  request_allow_at      :datetime
#  request_denny_at      :datetime
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
