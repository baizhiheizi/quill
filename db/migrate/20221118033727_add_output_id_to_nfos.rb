class AddOutputIdToNfos < ActiveRecord::Migration[7.0]
  def change
    add_column :non_fungible_outputs, :output_id, :uuid

    NonFungibleOutput.all.each do |nfo|
      nfo.update output_id: nfo.raw['output_id']
    end
  end
end
