class RemoveArticleBlockedState < ActiveRecord::Migration[7.0]
  def change
    Article.where(state: :blocked).each do |article|
      article.update state: :hidden
    end 
  end
end
