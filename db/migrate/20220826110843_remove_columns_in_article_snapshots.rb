class RemoveColumnsInArticleSnapshots < ActiveRecord::Migration[7.0]
  def change
    remove_column :article_snapshots, :file_content, :text
    remove_column :article_snapshots, :file_hash, :string
    remove_column :article_snapshots, :requested_at, :datetime
    remove_column :article_snapshots, :signed_at, :datetime
    remove_column :article_snapshots, :tx_id, :string
    remove_column :article_snapshots, :state, :string
  end
end
