class CreateTaggings < ActiveRecord::Migration[6.1]
  def change
    create_table :taggings do |t|
      t.belongs_to :tag
      t.belongs_to :article
      t.index [:tag_id, :article_id], unique: true
      t.timestamps
    end
  end
end
