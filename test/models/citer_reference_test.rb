# frozen_string_literal: true

# == Schema Information
#
# Table name: citer_references
#
#  id             :integer          not null, primary key
#  citer_type     :string
#  citer_id       :integer
#  reference_type :string
#  reference_id   :integer
#  revenue_ratio  :float            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_citer_references_on_citer      (citer_type,citer_id)
#  index_citer_references_on_reference  (reference_type,reference_id)
#

require 'test_helper'

class CiterReferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
