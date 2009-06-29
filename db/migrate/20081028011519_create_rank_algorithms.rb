class CreateRankAlgorithms < ActiveRecord::Migration
  def self.up
    create_table :rank_algorithms do |t|
      t.string :name, :null => false
      t.string :data, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :rank_algorithms
  end
end