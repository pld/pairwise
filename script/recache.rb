all_wins = Prompt.all(
  :select => "items_votes.item_id, prompts.question_id, COUNT(*) AS count",
  :joins => "INNER JOIN votes ON (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (votes.id=items_votes.vote_id)",
  :group => "items_votes.item_id, prompts.question_id"
)
all_ratings = Prompt.all(
  :select => "items_prompts.item_id, prompts.question_id, COUNT(*) AS count",
  :joins => "INNER JOIN items_prompts ON (prompts.id=items_prompts.prompt_id) INNER JOIN votes ON (votes.prompt_id=prompts.id)",
  :group => "items_prompts.item_id, prompts.question_id"
)
all_ratings_no_skips = Prompt.all(
  :select => "items_prompts.item_id, prompts.question_id, COUNT(*) AS count",
  :joins => "INNER JOIN items_prompts ON (prompts.id=items_prompts.prompt_id) INNER JOIN votes ON (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (votes.id=items_votes.vote_id)",
  :group => "items_prompts.item_id, prompts.question_id"
)
ItemsQuestion.transaction do
  for iq in ItemsQuestion.all
    wins = all_wins.find { |w| w.item_id.to_i == iq.item_id && w.question_id.to_i == iq.question_id }
    ratings = all_ratings.find { |w| w.item_id.to_i == iq.item_id && w.question_id.to_i == iq.question_id }
    ratings_no_skips = all_ratings_no_skips.find { |w| w.item_id.to_i == iq.item_id && w.question_id.to_i == iq.question_id }
    if ratings
      wins = wins ? wins.count.to_i : 0
      ratings_no_skips = ratings_no_skips ? ratings_no_skips.count.to_i : 0
#      puts "r:#{ratings.count} w:#{wins} l:#{ratings_no_skips - wins}"
      iq.update_attributes(
        :ratings => ratings.count,
        :wins => wins,
        :losses => ratings_no_skips - wins
      )
    end
  end
end