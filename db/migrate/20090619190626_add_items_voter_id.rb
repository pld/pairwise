class AddItemsVoterId < ActiveRecord::Migration
  def self.up
    add_column :items, :voter_id, :integer
  end

  def self.down
    remove_column :items, :voter_id
  end
end
