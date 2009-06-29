class AddItemsQuestionsLosses < ActiveRecord::Migration
  def self.up
    add_column :items_questions, :losses, :integer, :default => 0
  end

  def self.down
    remove_column :items_questions, :losses
  end
end
