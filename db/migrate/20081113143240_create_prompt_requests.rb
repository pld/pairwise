class CreatePromptRequests < ActiveRecord::Migration
  def self.up
    create_table :prompt_requests do |t|
      t.integer :question_id, :null => false
      t.integer :voter_id, :null => false
      t.integer :count, :default => 1
      t.text :item_ids
      t.timestamps
    end

    add_index :prompt_requests, :question_id
    add_index :prompt_requests, :voter_id
  end

  def self.down
    drop_table :prompt_requests
  end
end
