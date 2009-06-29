class CreateStats < ActiveRecord::Migration
  def self.up
    create_table :stats do |t|
      t.integer :question_id, :null => false
      t.integer :rank_algorithm_id
      t.integer :views, :null => false, :default => 0
      t.integer :votes, :null => false, :default => 0
      t.float :score, :null => false, :default => 0
      t.timestamps
    end

    create_table :items_stats, :id => false do |t|
      t.integer :item_id, :null => :false
      t.integer :stat_id, :null => :false
    end

    add_index :stats, :question_id
    add_index :items_stats, :item_id
    add_index :items_stats, :stat_id
  end

  def self.down
    drop_table :stats
    drop_table :items_stats
  end
end
