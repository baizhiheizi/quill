# frozen_string_literal: true

class AddLockVersionToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :lock_version, :integer, default: 0, null: false
  end
end
