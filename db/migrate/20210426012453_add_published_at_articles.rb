class AddPublishedAtArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :published_at, :datetime

    Article.only_published.each do |article|
      article.update published_at: article.created_at
    end
  end
end
