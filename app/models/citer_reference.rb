# frozen_string_literal: true

# == Schema Information
#
# Table name: citer_references
#
#  id             :bigint           not null, primary key
#  citer_type     :string
#  reference_type :string
#  revenue_ratio  :float            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  citer_id       :bigint
#  reference_id   :bigint
#
# Indexes
#
#  index_citer_references_on_citer      (citer_type,citer_id)
#  index_citer_references_on_reference  (reference_type,reference_id)
#
class CiterReference < ApplicationRecord
  belongs_to :citer, polymorphic: true
  belongs_to :reference, polymorphic: true

  validates :reference_id, uniqueness: { scope: %i[citer_id citer_type reference_type] }
end
