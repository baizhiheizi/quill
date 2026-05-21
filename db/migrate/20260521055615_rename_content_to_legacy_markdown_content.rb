# frozen_string_literal: true

class RenameContentToLegacyMarkdownContent < ActiveRecord::Migration[8.1]
  def change
    rename_column :articles, :content, :legacy_markdown_content
    rename_column :comments, :content, :legacy_markdown_content
  end
end
