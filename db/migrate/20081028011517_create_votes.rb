class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.integer :prompt_id, :null => false
      t.integer :voter_id, :null => false
      t.integer :response_time
      t.timestamps
    end
    
    create_table :items_votes, :id => false do |t|
      t.integer :item_id, :null => false
      t.integer :vote_id, :null => false
    end

    add_index :votes, :prompt_id
    add_index :votes, :voter_id

    add_index :items_votes, :item_id
    add_index :items_votes, :vote_id
  end

  def self.down
    drop_table :votes
    drop_table :items_votes
  end
end