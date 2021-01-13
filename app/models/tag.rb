# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id             :bigint           not null, primary key
#  articles_count :integer          default(0)
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Tag < ApplicationRecord
  has_many :taggings, dependent: :nullify
  has_many :articles, through: :taggings, dependent: :nullify
end
