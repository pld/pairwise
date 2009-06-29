class PromptRequest < ActiveRecord::Base
  belongs_to :question
  belongs_to :voter
  has_and_belongs_to_many :items

  validates_numericality_of :question_id
  validates_numericality_of :voter_id
end
