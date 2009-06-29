class Item < ActiveRecord::Base
  belongs_to :user
  belongs_to :voter
  has_many :items_questions, :dependent => :destroy
  has_many :questions, :through => :items_questions
  has_and_belongs_to_many :prompts
  has_many :items_stats, :dependent => :destroy
  has_many :stats, :through => :items_stats
  has_and_belongs_to_many :votes
  has_and_belongs_to_many :prompt_requests

  validates_presence_of :user_id

  before_destroy :destroy_habtms

  attr_accessor :score

  def iq(question_id)
    items_questions.find_by_question_id(question_id)
  end

  def destroy_habtms
    Prompt.destroy(prompts)
    prompts.clear
    Stat.destroy(stats)
    stats.clear
    Vote.destroy(votes)
    votes.clear
    PromptRequest.destroy(prompt_requests)
    prompt_requests.clear
  end
end
