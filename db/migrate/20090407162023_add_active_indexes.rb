class AddActiveIndexes < ActiveRecord::Migration
  def self.up
    add_index :items, :active
  end

  def self.down
    remove_index :items, :active
  end
end
