# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  articles_count    :integer          default(0)
#  name              :string
#  subscribers_count :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Tag < ApplicationRecord
  COLORS = %w[gray magenta red orange gold lime green cyan blue purple].freeze

  has_many :taggings, dependent: :nullify
  has_many :articles, through: :taggings, dependent: :nullify

  validates :name, uniqueness: true

  def color
    @color ||= COLORS[id % COLORS.size]
  end
end
