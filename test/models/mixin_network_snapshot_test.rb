# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_snapshots
#
#  id             :bigint           not null, primary key
#  amount         :decimal(, )
#  data           :string
#  processed_at   :datetime
#  raw            :json
#  transferred_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  asset_id       :uuid
#  opponent_id    :uuid
#  snapshot_id    :uuid
#  trace_id       :uuid
#  user_id        :uuid
#
# Indexes
#
#  index_mixin_network_snapshots_on_trace_id  (trace_id) UNIQUE
#  index_mixin_network_snapshots_on_user_id   (user_id)
#
require 'test_helper'

class MixinNetworkSnapshotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
