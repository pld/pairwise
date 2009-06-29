module Algorithms::Prompt
  # Generate count number of prompts based on question and voter. Choose
  # generation algorithm based on prime.
  # ==== Return
  # An array of prompts
  # ==== Parameters
  # question_id<int>:: Prompts for this question ID.
  # voter_id<int>:: Prompts for this voter ID.
  # count<int>:: This number of prompts.
  # prompt<bool>:: If true primed prompts are generated, otherwise random
  # prompts are generated.
  def create_prompts(question_id, voter_id, count, algo)
    srand if PRODUCTION
    case algo
    when 2
      result = ActiveRecord::Base.connection.execute(
        "SELECT id,score FROM stats WHERE question_id=#{question_id} ORDER BY score;"
      )
      # TODO: choose min value with more justification
      if result.num_rows > 2
        prompts = Algorithms::Prompt::Popular.prompts(question_id, voter_id, count, result)
      end
    when 3
      prompts = Algorithms::Prompt::Extremes.prompts(question_id, voter_id, count)
    end
    prompts || Algorithms::Prompt::Random.prompts(question_id, voter_id, count)
  end

  # Create default prompt
  def prompt_for_request(question_id, voter_id, algorithm_id)
    Prompt.create(
      :question_id => question_id,
      :voter_id => voter_id,
      :prompt_algorithm_id => algorithm_id,
      :active => false
    )
  end

  # Test if prompt is bad.  Prompt is bad if it does not have 2 items or if
  # any of its items are nil.
  def bad_prompt?(prompt)
    return (prompt.items.length != 2 || prompt.items.any?(&:nil?))
  end

  def conditions(question_id)
    {
      :joins => "INNER JOIN items_questions ON (items_questions.question_id=#{question_id} AND items_questions.item_id=items.id)",
      :conditions => { :active => true },
    }
  end

  private
    def items_for_request(question_id)
      Item.all(conditions(question_id).merge(:group => "items.id"))
    end
end