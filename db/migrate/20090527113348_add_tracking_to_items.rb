class AddTrackingToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :tracking, :text
  end

  def self.down
    remove_column :items, :tracking
  end
end
