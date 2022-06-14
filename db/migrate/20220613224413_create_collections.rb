class CreateCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :collections do |t|
      t.belongs_to :author
      t.uuid :uuid, index: { unique: true }
      t.string :name
      t.text :description

      t.timestamps
    end

    add_reference :articles, :collection
  end
end
