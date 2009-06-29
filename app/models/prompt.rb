class Prompt < ActiveRecord::Base
  belongs_to :question
  belongs_to :prompt_algorithm
  belongs_to :voter
  has_one :vote, :dependent => :destroy
  has_and_belongs_to_many :items

  validates_presence_of :question_id
  validates_presence_of :prompt_algorithm_id
  validates_presence_of :voter_id

  class << self
    include Algorithms::Prompt
    
    # Create prompts based on conditions. If prime is true items used in prompts
    # are relative to their stats values.  Otherwise items used are randomly
    # chosen.
    # ==== Return
    # Array of prompt ids.
    # ==== Parameters
    # question_id<int>:: The question id.
    # voter_id<int>:: The voter id.
    # count<int>:: The number of prompts to generate.
    # algo<int>:: If exists, id of prompt algorithm to use.
    # Otherwise not.
    def fetch(question_id, voter_id, count, algo)
      Item.count(conditions(question_id)) > 1 ? create_prompts(question_id, voter_id, count, algo) : {}
    end
  end
end