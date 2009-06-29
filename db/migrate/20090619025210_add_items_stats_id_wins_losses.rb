class AddItemsStatsIdWinsLosses < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE items_stats ADD id INT NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (id);")
    change_column :items_stats, :item_id, :integer, :null => false
    change_column :items_stats, :stat_id, :integer, :null => false
    add_column :items_stats, :losses, :integer, :default => 0
    add_column :items_stats, :wins, :integer, :default => 0
  end

  def self.down
    remove_column :items_stats, :id
    change_column :items_stats, :item_id, :integer
    change_column :items_stats, :stat_id, :integer
    remove_column :items_stats, :losses
    remove_column :items_stats, :wins
  end
end
