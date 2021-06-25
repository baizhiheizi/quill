# frozen_string_literal: true

# == Schema Information
#
# Table name: statistics
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  datetime   :datetime
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Statistic < ApplicationRecord
end
