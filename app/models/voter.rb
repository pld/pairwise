class Voter < ActiveRecord::Base
  has_many :features, :dependent => :destroy
  belongs_to :user
  belongs_to :prompt

  validates_presence_of :user_id
end
