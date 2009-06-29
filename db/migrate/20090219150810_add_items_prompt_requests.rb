class AddItemsPromptRequests < ActiveRecord::Migration
  def self.up
    remove_column :prompt_requests, :item_ids

    create_table :items_prompt_requests, :id => false do |t|
      t.integer :item_id, :null => false
      t.integer :prompt_request_id, :null => false
    end

    add_index :items_prompt_requests, :item_id
    add_index :items_prompt_requests, :prompt_request_id
  end

  def self.down
    add_column :prompt_requests, :item_ids, :text

    drop_table :items_prompt_requests
  end
end
