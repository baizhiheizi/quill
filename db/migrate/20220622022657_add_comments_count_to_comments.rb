class AddCommentsCountToComments < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :comments_count, :integer, default: 0
    add_reference :comments, :quote_comment
  end
end
