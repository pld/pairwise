class Feature < ActiveRecord::Base
  belongs_to :voter

  validates_presence_of :voter_id
  validates_presence_of :name
  validates_presence_of :value
end
