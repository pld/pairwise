class CreatePrompts < ActiveRecord::Migration
  def self.up
    create_table :prompts do |t|
      t.integer :question_id, :null => false
      t.integer :prompt_algorithm_id, :null => false
      t.integer :voter_id, :null => false
      t.boolean :active, :default => true
      t.timestamps
    end
      
    create_table :items_prompts, :id => false do |t|
      t.integer :item_id, :null => false
      t.integer :prompt_id, :null => false
    end

    add_index :prompts, :question_id
    add_index :prompts, :voter_id

    add_index :items_prompts, :item_id
    add_index :items_prompts, :prompt_id
  end

  def self.down
    drop_table :prompts
    drop_table :items_prompts
  end
end