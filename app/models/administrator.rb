# frozen_string_literal: true

# == Schema Information
#
# Table name: administrators
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_administrators_on_name  (name) UNIQUE
#
class Administrator < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_secure_password
end
