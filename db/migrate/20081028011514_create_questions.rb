class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.timestamps
    end

    add_index :questions, :user_id
  end

  def self.down
    drop_table :questions
  end
end
