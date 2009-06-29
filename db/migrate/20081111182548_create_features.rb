class CreateFeatures < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.integer :voter_id, :null => false
      t.string :name, :null => false
      t.integer :value, :null => false

      t.timestamps
    end

    add_index :features, :voter_id
    add_index :features, :name
  end

  def self.down
    drop_table :features
  end
end
