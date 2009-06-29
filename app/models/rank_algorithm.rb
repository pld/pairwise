class RankAlgorithm < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :data
end
