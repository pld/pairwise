class Vote < ActiveRecord::Base
  belongs_to :prompt
  belongs_to :voter
  has_and_belongs_to_many :items

  validates_presence_of :prompt_id
  validates_uniqueness_of :prompt_id
  validates_presence_of :voter_id
end
