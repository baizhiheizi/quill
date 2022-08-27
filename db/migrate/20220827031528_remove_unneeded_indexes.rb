class RemoveUnneededIndexes < ActiveRecord::Migration[7.0]
  def change
    remove_index :taggings, name: "index_taggings_on_tag_id", column: :tag_id
    remove_index :taggings, name: "index_taggings_on_article_id", column: :article_id
  end
end
