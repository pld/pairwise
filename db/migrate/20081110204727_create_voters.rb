class CreateVoters < ActiveRecord::Migration
  def self.up
    create_table :voters do |t|
      t.integer :user_id, :null => false
      t.timestamps
    end

    add_index :voters, :user_id
  end

  def self.down
    drop_table :voters
  end
end
