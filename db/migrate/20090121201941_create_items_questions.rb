class CreateItemsQuestions < ActiveRecord::Migration
  def self.up
    create_table :items_questions do |t|
      t.integer :item_id, :null => false
      t.integer :question_id, :null => false
      t.integer :position, :default => 1400, :null => false
      t.integer :wins, :default => 0, :null => false
      t.integer :ratings, :default => 0, :null => false
      t.timestamps
    end

    add_index :items_questions, :item_id
    add_index :items_questions, :question_id
  end

  def self.down
    drop_table :items_questions
  end
end
