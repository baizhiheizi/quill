class AddLocaleToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :locale, :string
  end
end
