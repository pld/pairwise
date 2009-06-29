class AddTrackingToVotes < ActiveRecord::Migration
  def self.up
    add_column :votes, :tracking, :text
  end

  def self.down
    remove_column :votes, :tracking
  end
end
