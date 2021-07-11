class CreateCiterReferences < ActiveRecord::Migration[6.1]
  def change
    create_table :citer_references do |t|
      t.belongs_to :citer, polymorphic: true
      t.belongs_to :reference, polymorphic: true
      t.float :revenue_ratio, null: false

      t.timestamps
    end
  end
end
