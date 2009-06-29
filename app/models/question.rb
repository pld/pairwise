class Question < ActiveRecord::Base
  belongs_to :user
  has_many :items_questions, :dependent => :destroy
  has_many :items, :through => :items_questions
  has_many :prompts, :dependent => :destroy
  has_many :prompt_requests, :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :name
end
