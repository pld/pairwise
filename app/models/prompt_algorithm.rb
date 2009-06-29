class PromptAlgorithm < ActiveRecord::Base
  has_many :prompts

  validates_presence_of :name
  validates_presence_of :data
end
