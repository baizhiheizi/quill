# frozen_string_literal: true

# == Schema Information
#
# Table name: statistics
#
#  id         :integer          not null, primary key
#  type       :string
#  datetime   :datetime
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Statistic < ApplicationRecord
end
