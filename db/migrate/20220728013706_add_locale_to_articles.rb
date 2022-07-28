class AddLocaleToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :locale, :string
  end
end
